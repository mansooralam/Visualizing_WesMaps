"""Scrapes department codes, course codes, and course prerequisites."""


import csv
import re
import time
import urllib.parse

import bs4
import requests


ROOT_URL = 'https://iasext.wesleyan.edu/regprod/!wesmaps_page.html'


def get_soup(payload):
    resp = requests.get(ROOT_URL, params=payload)
    soup = bs4.BeautifulSoup(resp.text)
    return soup


def get_queries(url):
    parsed = urllib.parse.urlparse(url)
    queries = urllib.parse.parse_qs(parsed.query)
    return queries


def get_department_codes():
    soup = get_soup(None)
    departments = soup.find_all(href=re.compile('subj_page'))
    departments = [get_queries(i['href']) for i in departments]
    departments = {i['subj_page'][0] for i in departments}
    return departments


def get_course_codes(department_code):
    soup = get_soup({'crse_list': department_code, 'offered': 'Y'})
    courses = []
    for course in soup.find_all(href=re.compile('crse'), class_=None):
        queries = get_queries(course['href'])
        code = queries['crse'][0]
        term = queries['term'][0]
        number = course.text.split('-')[0]
        courses.append((code, number, term))
    return courses


def get_prerequisites(course_code, term):
    soup = get_soup({'crse': course_code, 'term': term})
    prereqs = soup.find('b', text='Prerequisites: ').parent.text
    prereqs = prereqs.replace('Prerequisites: ', '')
    return prereqs


def main():
    wesmaps = []
    for department_code in get_department_codes():
        for code, number, term in get_course_codes(department_code):
            prerequisites = get_prerequisites(code, term)
            wesmaps.append((department_code, number, prerequisites))
            time.sleep(1)

    with open('Data/Raw.csv', 'w') as f:
        writer = csv.writer(f)
        writer.writerows(wesmaps)


if __name__ == '__main__':
    main()


