#!/bin/bash
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

if getarg rd.convertfs; then
    if getarg rd.debug; then
        bash -x convertfs "$NEWROOT" 2>&1 | vinfo
    else
        convertfs "$NEWROOT" 2>&1 | vinfo
    fi
    mount "$NEWROOT" -o remount,ro
fi
