# Verify every definition.
#
#   make    verify everything with everparse
#
# The work is in check.sh, which tries each definition in a directory of its own, so
# there is nothing left here to clean.

all: check

check:
	sh ./check.sh

.PHONY: all check
