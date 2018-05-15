/* This file is part of the YAZ toolkit.
 * Copyright (C) Index Data
 * See the file LICENSE for details.
 */
/**
 * \file url.c
 * \brief URL fetch utility
 */
#if HAVE_CONFIG_H
#include <config.h>
#endif

#include <yaz/url.h>
#include <yaz/comstack.h>
#include <yaz/log.h>
#include <yaz/wrbuf.h>
#include <yaz/cookie.h>
#include <yaz/poll.h>

struct yaz_url {
    ODR odr_in;
    ODR odr_out;
    char *proxy;
    int max_redirects;
    WRBUF w_error;
    int verbose;
    int timeout_sec;
    int timeout_ns;
    yaz_cookies_t cookies;
};

yaz_url_t yaz_url_create(void)
{
    yaz_url_t p = xmalloc(sizeof(*p));
    p->odr_in = odr_createmem(ODR_DECODE);
    p->odr_out = odr_createmem(ODR_ENCODE);
    p->proxy = 0;
    p->max_redirects = 10;
    p->w_error = wrbuf_alloc();
    p->verbose = 0;
    p->timeout_sec = 30;
    p->timeout_ns = 0;
    p->cookies = yaz_cookies_create();
    return p;
}

void yaz_url_destroy(yaz_url_t p)
{
    if (p)
    {
        odr_destroy(p->odr_in);
        odr_destroy(p->odr_out);
        xfree(p->proxy);
        wrbuf_destroy(p->w_error);
        yaz_cookies_destroy(p->cookies);
        xfree(p);
    }
}

void yaz_url_set_proxy(yaz_url_t p, const char *proxy)
{
    xfree(p->proxy);
    p->proxy = 0;
    if (proxy && *proxy)
        p->proxy = xstrdup(proxy);
}

void yaz_url_set_max_redirects(yaz_url_t p, int num)
{
    p->max_redirects = num;
}

void yaz_url_set_verbose(yaz_url_t p, int num)
{
    p->verbose = num;
}

void yaz_url_set_timeout(yaz_url_t p, int sec, int ns)
{
    p->timeout_sec = sec;
    p->timeout_ns = ns;
}

static void extract_user_pass(NMEM nmem,
                              const char *uri,
                              char **uri_lean, char **http_user,
                              char **http_pass)
{
    const char *cp1 = strchr(uri, '/');
    *uri_lean = 0;
    *http_user = 0;
    *http_pass = 0;
    if (cp1 && cp1 > uri)
    {
        cp1--;

        if (!strncmp(cp1, "://", 3))
        {
            const char *cp3 = 0;
            const char *cp2 = cp1 + 3;
            while (*cp2 && *cp2 != '/' && *cp2 != '@')
            {
                if (*cp2 == ':')
                    cp3 = cp2;
                cp2++;
            }
            if (*cp2 == '@' && cp3)
            {
                *uri_lean = nmem_malloc(nmem, strlen(uri) + 1);
                memcpy(*uri_lean, uri, cp1 + 3 - uri);
                strcpy(*uri_lean + (cp1 + 3 - uri), cp2 + 1);

                *http_user = nmem_strdupn(nmem, cp1 + 3, cp3 - (cp1 + 3));
                *http_pass = nmem_strdupn(nmem, cp3 + 1, cp2 - (cp3 + 1));
            }
        }
    }
    if (*uri_lean == 0)
        *uri_lean = nmem_strdup(nmem, uri);
}

const char *yaz_url_get_error(yaz_url_t p)
{
    return wrbuf_cstr(p->w_error);
}

static void log_warn(yaz_url_t p)
{
    yaz_log(YLOG_WARN, "yaz_url: %s", wrbuf_cstr(p->w_error));
}

Z_HTTP_Response *yaz_url_exec(yaz_url_t p, const char *uri,
                              const char *method,
                              Z_HTTP_Header *user_headers,
                              const char *buf, size_t len)
{
    Z_HTTP_Response *res = 0;
    int number_of_redirects = 0;

    odr_reset(p->odr_out);
    yaz_cookies_reset(p->cookies);
    wrbuf_rewind(p->w_error);
    while (1)
    {
        void *add;
        COMSTACK conn = 0;
        int code;
        const char *location = 0;
        char *http_user = 0;
        char *http_pass = 0;
        char *uri_lean = 0;
        int proxy_mode = 0;

        extract_user_pass(p->odr_out->mem, uri, &uri_lean,
                          &http_user, &http_pass);
        conn = cs_create_host2(uri_lean, 0, &add, p->proxy, &proxy_mode);
        if (!conn)
        {
            wrbuf_printf(p->w_error, "Can not resolve URL %s", uri);
            log_warn(p);
        }
        else
        {
            int ret;
            Z_GDU *gdu =
                z_get_HTTP_Request_uri(p->odr_out, uri_lean, 0, proxy_mode);
            gdu->u.HTTP_Request->method = odr_strdup(p->odr_out, method);
            yaz_cookies_request(p->cookies, p->odr_out, gdu->u.HTTP_Request);
            for ( ; user_headers; user_headers = user_headers->next)
            {
                /* prefer new Host over user-supplied Host */
                if (!strcmp(user_headers->name, "Host"))
                    ;
                /* prefer user-supplied User-Agent over YAZ' own */
                else if (!strcmp(user_headers->name, "User-Agent"))
                    z_HTTP_header_set(p->odr_out, &gdu->u.HTTP_Request->headers,
                                      user_headers->name, user_headers->value);
                else
                    z_HTTP_header_add(p->odr_out, &gdu->u.HTTP_Request->headers,
                                      user_headers->name, user_headers->value);
            }
            if (http_user && http_pass)
                z_HTTP_header_add_basic_auth(p->odr_out,
                                             &gdu->u.HTTP_Request->headers,
                                             http_user, http_pass);
            res = 0;
            if (buf && len)
            {
                gdu->u.HTTP_Request->content_buf = (char *) buf;
                gdu->u.HTTP_Request->content_len = len;
            }
            if (!z_GDU(p->odr_out, &gdu, 0, 0))
            {
                wrbuf_printf(p->w_error, "Can not encode HTTP request for URL %s",
                             uri);
                log_warn(p);
                return 0;
            }
            ret = cs_connect(conn, add);
            if (ret < 0) /* error */
            {
                wrbuf_printf(p->w_error, "Can not connect to URL %s", uri);
                log_warn(p);
            }
            else
            {
                char *netbuffer = 0;
                int netlen = 0;
                int len_out;
                char *buf_out = odr_getbuf(p->odr_out, &len_out, 0);
                int state = 0; /* 0=connect phase, 1=send, 2=recv */

                if (p->verbose)
                    fwrite(buf_out, 1, len_out, stdout);
                if (!strcmp(gdu->u.HTTP_Request->method, "HEAD"))
                    cs_set_head_only(conn, 1);
                if (ret == 0)
                    state = 1; /* connect complete, so send phase */
                while (1)
                {
                    if (ret == 1) /* incomplete , wait */
                    {
                        struct yaz_poll_fd yp;
                        enum yaz_poll_mask input_mask = yaz_poll_none;
                        yaz_poll_add(input_mask, yaz_poll_except);
                        if (conn->io_pending & CS_WANT_WRITE)
                            yaz_poll_add(input_mask, yaz_poll_write);
                        if (conn->io_pending & CS_WANT_READ)
                            yaz_poll_add(input_mask, yaz_poll_read);
                        yp.fd = cs_fileno(conn);
                        yp.input_mask = input_mask;
                        ret = yaz_poll(&yp, 1, p->timeout_sec, p->timeout_ns);
                        if (ret == 0)
                        {
                            wrbuf_printf(p->w_error, "timeout URL %s", uri);
                            break;
                        }
                        else if (ret < 0)
                        {
                            wrbuf_printf(p->w_error, "poll error URL %s", uri);
                            break;
                        }
                    }
                    if (state == 0) /* connect phase */
                    {
                        ret = cs_rcvconnect(conn);
                        if (ret < 0)
                        {
                            wrbuf_printf(p->w_error, "cs_rcvconnect failed for URL %s", uri);
                            log_warn(p);
                            break;
                        }
                        else if (ret == 0)
                            state = 1;
                    }
                    else if (state == 1) /* write request phase */
                    {
                        ret = cs_put(conn, buf_out, len_out);
                        if (ret < 0)
                        {
                            wrbuf_printf(p->w_error, "cs_put fail for URL %s", uri);
                            log_warn(p);
                        }
                        else if (ret == 0)
                        {
                            state = 2;
                        }
                    }
                    else if (state == 2) /* read response phase */
                    {
                        ret = cs_get(conn, &netbuffer, &netlen);
                        if (ret  <= 0)
                        {
                            wrbuf_printf(p->w_error, "cs_get failed for URL %s", uri);
                            log_warn(p);
                            break;
                        }
                        else if (ret > 1)
                        {
                            Z_GDU *gdu;
                            if (p->verbose)
                                fwrite(netbuffer, 1, ret, stdout);
                            odr_setbuf(p->odr_in, netbuffer, ret, 0);
                            if (!z_GDU(p->odr_in, &gdu, 0, 0)
                                || gdu->which != Z_GDU_HTTP_Response)
                            {
                                wrbuf_printf(p->w_error, "HTTP decoding fail for "
                                             "URL %s", uri);
                                log_warn(p);
                            }
                            else
                            {
                                res = gdu->u.HTTP_Response;
                                break;
                            }
                        }
                    }
                }
                xfree(netbuffer);
            }
            cs_close(conn);
        }
        if (!res)
            break;
        code = res->code;
        location = z_HTTP_header_lookup(res->headers, "Location");
        if (++number_of_redirects <= p->max_redirects &&
            location && (code == 301 || code == 302 || code == 307))
        {
            int host_change = 0;
            const char *nlocation = yaz_check_location(p->odr_in, uri,
                                                       location, &host_change);

            odr_reset(p->odr_out);
            uri = odr_strdup(p->odr_out, nlocation);
        }
        else
            break;
        yaz_cookies_response(p->cookies, res);
        odr_reset(p->odr_in);
    }
    return res;
}

/*
 * Local variables:
 * c-basic-offset: 4
 * c-file-style: "Stroustrup"
 * indent-tabs-mode: nil
 * End:
 * vim: shiftwidth=4 tabstop=8 expandtab
 */

