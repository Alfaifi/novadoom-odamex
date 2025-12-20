#!/usr/bin/env python3

# -----------------------------------------------------------------------------
#
# $Id: $
#
# Copyright (C) 2006-2025 by The Odamex Team.
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# DESCRIPTION:
#  A tool used to help test novadoom/novasrv during development.
#
# -----------------------------------------------------------------------------

import shlex
import subprocess
from pathlib import Path
from tkinter import (
    Tk,
    Frame,
    Label,
    StringVar,
    Entry,
    Button,
    LEFT as SIDE_LEFT,
    DISABLED as STATE_DISABLED,
)

BUILD_DIR = Path(__file__).parent.parent.parent / "build"
NOVADOOM_EXE = BUILD_DIR / "client" / "Debug" / "novadoom.exe"
NOVADOOM_CWD = NOVADOOM_EXE.parent
NOVASRV_EXE = BUILD_DIR / "server" / "Debug" / "novasrv.exe"
NOVASRV_CWD = NOVASRV_EXE.parent
CONSOLE_CMD = ["wt.exe", "--window", "-1"]

root = Tk()

novadoom_params_sv = StringVar(root)
novadoom_params_sv.set("+connect localhost")
novasrv_params_sv = StringVar(root)


def run_novadoom():
    params = shlex.split(novadoom_params_sv.get())
    subprocess.Popen([NOVADOOM_EXE, *params], cwd=NOVADOOM_CWD)


def run_novasrv():
    params = shlex.split(novasrv_params_sv.get())
    subprocess.Popen([*CONSOLE_CMD, NOVASRV_EXE, *params], cwd=NOVASRV_CWD)


paths_f = Frame(root)
paths_f.pack()
buttons_f = Frame(root)
buttons_f.pack()

novadoom_l = Label(paths_f, text="NovaDoom")
novadoom_l.grid(row=1, column=1)
novadoom_sv = StringVar()
novadoom_sv.set(str(NOVADOOM_EXE))
novadoom_e = Entry(paths_f, state=STATE_DISABLED, textvariable=novadoom_sv, width=100)
novadoom_e.grid(row=1, column=2)

novadoom_params_e = Entry(paths_f, textvariable=novadoom_params_sv, width=100)
novadoom_params_e.grid(row=2, column=2)

novasrv_l = Label(paths_f, text="Novasrv")
novasrv_l.grid(row=3, column=1)
novasrv_sv = StringVar()
novasrv_sv.set(str(NOVASRV_EXE))
novasrv_e = Entry(paths_f, state=STATE_DISABLED, textvariable=novasrv_sv, width=100)
novasrv_e.grid(row=3, column=2)

novasrv_params_e = Entry(paths_f, textvariable=novasrv_params_sv, width=100)
novasrv_params_e.grid(row=4, column=2)

novadoom_b = Button(buttons_f, text="Run NovaDoom", command=run_novadoom)
novadoom_b.pack(side=SIDE_LEFT)
novasrv_b = Button(buttons_f, text="Run Novasrv", command=run_novasrv)
novasrv_b.pack(side=SIDE_LEFT)

root.title("Run Built NovaDoom")
root.mainloop()
