# -*- coding: utf-8 -*-

"""
typograf.py
Python 3 client for ArtLebedevStudio.RemoteTypograf web-service.

Service: http://typograf.artlebedev.ru/webservices/typograf.asmx
Docs:    http://typograf.artlebedev.ru/

Based on the original Python 2 implementation by Sergey Lavrinenko,
itself based on a script by Andrew Shitov. Rewritten for Python 3
using only the standard library.

Usage as a module:
    from typograf import RemoteTypograf
    rt = RemoteTypograf()
    print(rt.process_text('"Какие-то" кавычки - и тире.'))

Usage as a CLI (reads stdin, writes stdout):
    echo '"Текст" - с типографикой' | python3 typograf.py
    python3 typograf.py < post.md > post.typo.md
"""

import html
import http.client
import sys

HOST = "typograf.artlebedev.ru"
PATH = "/webservices/typograf.asmx"
SOAP_ACTION = "http://typograf.artlebedev.ru/webservices/ProcessText"

# entityType values accepted by the service
ENTITY_HTML = 1   # &laquo; etc.
ENTITY_XML = 2    # &#171; etc.
ENTITY_NONE = 3   # raw unicode characters
ENTITY_MIXED = 4  # mixed


class RemoteTypograf:
    def __init__(self, encoding="UTF-8", timeout=30):
        self._encoding = encoding
        self._timeout = timeout
        self._entity_type = ENTITY_MIXED
        self._use_br = 1
        self._use_p = 1
        self._max_nobr = 3

    def html_entities(self):
        self._entity_type = ENTITY_HTML

    def xml_entities(self):
        self._entity_type = ENTITY_XML

    def mixed_entities(self):
        self._entity_type = ENTITY_MIXED

    def no_entities(self):
        self._entity_type = ENTITY_NONE

    def br(self, value):
        self._use_br = 1 if value else 0

    def p(self, value):
        self._use_p = 1 if value else 0

    def nobr(self, value):
        self._max_nobr = value if value else 0

    def _build_envelope(self, text):
        escaped = html.escape(text, quote=False)
        return (
            '<?xml version="1.0" encoding="%s"?>\n'
            '<soap:Envelope '
            'xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" '
            'xmlns:xsd="http://www.w3.org/2001/XMLSchema" '
            'xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">\n'
            '<soap:Body>\n'
            ' <ProcessText xmlns="http://typograf.artlebedev.ru/webservices/">\n'
            '  <text>%s</text>\n'
            '  <entityType>%s</entityType>\n'
            '  <useBr>%s</useBr>\n'
            '  <useP>%s</useP>\n'
            '  <maxNobr>%s</maxNobr>\n'
            ' </ProcessText>\n'
            '</soap:Body>\n'
            '</soap:Envelope>\n'
        ) % (
            self._encoding,
            escaped,
            self._entity_type,
            self._use_br,
            self._use_p,
            self._max_nobr,
        )

    def process_text(self, text):
        body = self._build_envelope(text).encode(self._encoding)
        headers = {
            "Host": HOST,
            "Content-Type": "text/xml; charset=%s" % self._encoding,
            "Content-Length": str(len(body)),
            "SOAPAction": '"%s"' % SOAP_ACTION,
        }

        conn = http.client.HTTPConnection(HOST, 80, timeout=self._timeout)
        try:
            conn.request("POST", PATH, body=body, headers=headers)
            response = conn.getresponse()
            if response.status != 200:
                raise RuntimeError(
                    "Typograf service returned HTTP %s %s"
                    % (response.status, response.reason)
                )
            raw = response.read().decode(self._encoding, errors="replace")
        finally:
            conn.close()

        start_tag = "<ProcessTextResult>"
        end_tag = "</ProcessTextResult>"
        start = raw.find(start_tag)
        end = raw.find(end_tag)
        if start == -1 or end == -1:
            raise RuntimeError("Unexpected response from Typograf service")

        result = raw[start + len(start_tag):end]
        # The result is XML-escaped once inside the SOAP envelope.
        return html.unescape(result)


def main(argv=None):
    text = sys.stdin.read()
    rt = RemoteTypograf()
    rt.no_entities()  # keep raw unicode «», — etc. for Markdown/plain text
    rt.br(0)
    rt.p(0)
    rt.nobr(3)
    sys.stdout.write(rt.process_text(text))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
