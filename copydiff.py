#!/usr/bin/env python2
#Author Phinfinity <rndanish@gmail.com>
'''
This is an attempt by me to write a copy-case detector. It has been
inspired by the diligent efforts by undergraduate students everywhere ;)
'''
import argparse
import os
import re
import sys
from collections import defaultdict
from hashlib import md5
from itertools import combinations

ROOT_DIR = "." # Directory to start crawling at
TRUNCATE_LENGTH=40 # Length to truncate filenames to for display
MIN_PERCENT_MATCH_TO_DSIPLAY = 30.0 # this is only for display not calculation
MIN_LINES_MATCH_TO_DISPLAY = 10 # in addition to percentage
SIZE_LIMIT = 1024*32 # Don't process files bigger than 64K
LINE_TRUNC = 512 # Truncate long lines to first this many characters
REPEAT_TOLERANCE = 10 # Ignore digests which repeat more than 10 times
IGNORE_EXTENSIONS = [".class", ".jar", ".html", ".txt", ".xml", ".png", ".gif", ".css"]
EXTENDED_FILE_PRINT = False
space_remover = re.compile('\s')
digest_list = {} # digest -> line eof text mapping
file_lines = {}

def set_constants_from_argumentes():
    global ROOT_DIR, TRUNCATE_LENGTH, MIN_PERCENT_MATCH_TO_DSIPLAY
    global MIN_LINES_MATCH_TO_DISPLAY, SIZE_LIMIT, LINE_TRUNC, REPEAT_TOLERANCE
    global IGNORE_EXTENSIONS, EXTENDED_FILE_PRINT
    parser = argparse.ArgumentParser()
    parser.add_argument("root_directory",
            help="Root directory to start crawling at. \
                    Every folder inside this is treated as separate submission.\
                    Defaults to current directory.",
            nargs='?',
            default=ROOT_DIR)
    parser.add_argument("-e", "--extended_list", action="store_true",
            help="Enable listing copied files for each submission.")
    parser.add_argument("--repeat_tolerance", "-r", type=int, default=REPEAT_TOLERANCE,
            help="If a section of code occurs more than this many times , it will be treated as boilerplate \
                    and won't be counted towards copied code sections. For performance reasons this needs to \
                    be a small numbers, bigger numbers will quadratically slow down. Defaults to %d" % REPEAT_TOLERANCE)
    parser.add_argument("--size_limit", "-s", type=int, default=SIZE_LIMIT,
            help="Minimum size of a file in bytes , for it to be checked as code for copying. \
                    Defaults to %d" % SIZE_LIMIT)
    parser.add_argument("--truncate_length", "-t", type=int, default=TRUNCATE_LENGTH,
            help="Number of characters to truncate display of files to. \
                     Defaults to %d" % TRUNCATE_LENGTH)
    parser.add_argument("--min_percent_display", "-p", type=float, default=MIN_PERCENT_MATCH_TO_DSIPLAY,
            help="Minimum percentage of file match required to display filename.\
                    Defaults to %.2f" % MIN_PERCENT_MATCH_TO_DSIPLAY)
    parser.add_argument("--min_lines_display", "-l", type=int, default=MIN_LINES_MATCH_TO_DISPLAY,
            help="Minimum number of lines a file match requires to display its name.\
                    Defaults to %d" % MIN_LINES_MATCH_TO_DISPLAY)
    parser.add_argument("--ignore_prefix", type=str, default=",".join(IGNORE_EXTENSIONS),
            help="comma separated list of extensions or file name suffixes to be ignored. Defaults to %s" % ",".join(IGNORE_EXTENSIONS))
    args = parser.parse_args()
    EXTENDED_FILE_PRINT = args.extended_list
    ROOT_DIR = args.root_directory
    TRUNCATE_LENGTH = args.truncate_length
    MIN_PERCENT_MATCH_TO_DSIPLAY = args.min_percent_display
    MIN_LINES_MATCH_TO_DISPLAY = args.min_lines_display
    SIZE_LIMIT = args.size_limit
    REPEAT_TOLERANCE = args.repeat_tolerance
    IGNORE_EXTENSIONS = args.ignore_prefix.split(",")
def trunc_txt(s):
    if len(s) > TRUNCATE_LENGTH:
        s = "..."+s[-32:]
    return s


def get_line_digests(file_name):
    ret_set = set()
    line_coutn = 0
    for line in open(file_name):
        line_coutn += 1
        strip_line = space_remover.sub('', line)
        dig = md5(strip_line).digest()
        if dig not in digest_list:
            digest_list[dig] = line[:LINE_TRUNC]
        ret_set.add(dig)
    file_lines[file_name] = line_coutn
    return ret_set

def handle_rollno(rollno, root_dir):
    dig_dict = {}
    for root,dirs,files in os.walk(root_dir):
        for fn in files:
            path = os.path.join(root, fn)
            size = os.stat(path).st_size
            if size > SIZE_LIMIT:
                continue
            valid_file = True
            for i in IGNORE_EXTENSIONS:
                if path.endswith(i):
                    valid_file = False
                    break
            if valid_file:
                for dig in get_line_digests(path):
                    dig_dict[dig] = path
    return dig_dict


def main():
    set_constants_from_argumentes()
    digest_wise = defaultdict(list)
    for rollno in os.listdir(ROOT_DIR):
        sys.stderr.write("Parsing %s        \r" % rollno)
        path = os.path.join(ROOT_DIR, rollno)
        if os.path.isdir(path):
            for dig,path in handle_rollno(rollno, path).items():
                digest_wise[dig].append((rollno,path))
    sys.stderr.write("Finished Parsing files\n")
    copy_set = filter(lambda x: len(x) <= REPEAT_TOLERANCE and len(x) > 1, digest_wise.values())
    copy_relations = defaultdict(int)
    copy_files = defaultdict(dict)
    for rollnos in copy_set:
        for pair in combinations(sorted(rollnos), 2):
            rtup = (pair[0][0], pair[1][0])
            ftup = (pair[0][1], pair[1][1])
            copy_relations[rtup] += 1
            if ftup not in copy_files[rtup]:
                copy_files[rtup][ftup] = 0
            copy_files[rtup][ftup] += 1

    top_edges = sorted(map(lambda x: (x[1],x[0]), copy_relations.items()))
    #for i in top_edges:
    #    print "%d : %s-%s" % (i[0], i[1][0], i[1][1])
    for i in top_edges:
        rtup = i[1]
        files = sorted(map(lambda x: (x[1],x[0]), copy_files[rtup].items()))
        print "%d : %s-%s" % (i[0], i[1][0], i[1][1])
        if not EXTENDED_FILE_PRINT:
            continue
        for j in files:
            l1 = file_lines[j[1][0]]
            l2 = file_lines[j[1][1]]
            m = (100.0*j[0])/min(l1,l2)
            if m >= MIN_PERCENT_MATCH_TO_DSIPLAY and j[0] >= MIN_LINES_MATCH_TO_DISPLAY:
                print "%7.2f%%(%4d) %35s %35s" % (m,j[0],trunc_txt(j[1][0]),trunc_txt(j[1][1]))




if __name__ == "__main__":
    main()
