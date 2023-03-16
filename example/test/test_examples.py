"""A tiny example binary for the native Python rules of Bazel."""
import unittest
import re

import lxml
import pypdf

from bs4 import BeautifulSoup

from reportlab.graphics import renderPDF
from svglib.svglib import svg2rlg


def verify_against_my_report_tex(gen_text):
    with open("./example/my_report.tex") as fd:
        ref_text = fd.read()

    title = re.findall(r"\\title\{([a-zA-Z0-9 \-]*)\}", ref_text, re.MULTILINE)[0].replace(" ", "")
    author = re.findall(r"\\author\{([a-zA-Z0-9 \-]*)\}", ref_text, re.MULTILINE)[0].replace(" ", "")
    date = re.findall(r"\\date\{([a-zA-Z0-9 \-]*)\}", ref_text, re.MULTILINE)[0].replace(" ", "")

    assert title in gen_text, [ref_text, gen_text]
    assert author in gen_text, [ref_text, gen_text]
    assert date in gen_text, [ref_text, gen_text]


def extract_and_verify(in_file):
    with open(in_file) as fd:
        gen_data = fd.read()
    soup = BeautifulSoup(gen_data, 'xml')

    text_items = soup.find_all('text')
    text =[]
    for item  in text_items:
        text.append(item.text)
    text = "\n".join(text)
    verify_against_my_report_tex(text)
    drawing = svg2rlg(in_file)
    renderPDF.drawToFile(drawing, "my_pdf_report.pdf")
    reader = pypdf.PdfReader("my_pdf_report.pdf")
    number_of_pages = len(reader.pages)
    page = reader.pages[0]
    gen_text = page.extract_text()
    gen_text = gen_text.replace(" ","").replace("\n", "")
    verify_against_my_report_tex(gen_text)


class TestGetNumber(unittest.TestCase):

    def test_pdf(self):
        reader = pypdf.PdfReader("./example/my_report.pdf")
        number_of_pages = len(reader.pages)
        page = reader.pages[0]
        gen_text = page.extract_text()
        gen_text = gen_text.replace(" ","").replace("\n", "")
        verify_against_my_report_tex(gen_text)

    # dvisvgm doesn't support text object in svg from pdf until version 3.0
    @unittest.expectedFailure
    def test_pdf_svg(self):
        extract_and_verify("./example/my_svg_report_from_pdf_svg/my_svg_report_from_pdf_svg-1.svg")

    def test_dvi_svg(self):
        extract_and_verify("./example/my_svg_report_from_dvi_svg/my_svg_report_from_dvi_svg-1.svg")

if __name__ == '__main__':
    unittest.main()
