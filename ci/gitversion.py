#!/usr/bin/python
# -*- coding: utf-8 -*-

import os
import sys

key = sys.argv[1]
image = sys.argv[2]

gv = {}

command = 'docker run --rm -v "$(pwd):/repo" '+image+' /repo'
command_d = 'docker run --rm -v "$(pwd):/repo" '+image+' /repo /diag'

f = os.popen(command)

try:
    gv = eval(f.read())
    print(gv[key])


except SyntaxError as e:
    diag = os.popen(command_d)
    print(diag.read())
