# -- [ Makefile ]
#
# A Makefile for the assignment.
#
# Unless otherwise instructed please do not change this, nor the other
# makefiles in the project.
#
# -- [ EOH ]

REGNO := 20241234
# ^ replace with your own student number.

CWORK := CS886-CW1

IDRIS2 := idris2
DAFNY  := dafny

BUILDDIR    := build
TARGET_NAME := cs886
TARGET_OUT  := ${PWD}/${BUILDDIR}/${TARGET_NAME}
TARGET      := ${TARGET_OUT}.dll

SOURCES := ${shell ls src/*.dfy}
OPTS := --target cs -o cs886

.PHONY: usage

usage:
	@echo "targets:"
	@echo ""
	@echo "## Submission"
	@echo ""
	@echo "submission -- generate a tar.gz for submitting project to MyPlace"
	@echo ""
	@echo "## Building"
	@echo ""
	@echo "cs886-parse  -- Parse the project"
	@echo "cs886-verify -- Verify the project"
	@echo "cs886-audit  -- Audit the project"
	@echo "cs886        -- Build the executable"
	@echo ""
	@echo "## Cleaning"
	@echo ""
	@echo "clean   -- Remove the build directory"
	@echo "clobber -- Remove all build artefacts"
	@echo ""
	@echo "## Testing"
	@echo ""
	@echo "cs886-test-build   -- Build the test harness"
	@echo "cs886-test-run     -- Run the rest harness"
	@echo "cs886-test-run-re  -- Rerun failing tests"
	@echo "cs886-test-update  -- Update expected output with given output"

# -- [ BUild ]

.PHONY: cs886-parse cs886-check cs886-audit cs886

## Parse the project
##
cs886-parse: $(SOURCES)
	${MAKE} -C src DAFNY=${DAFNY} cs886-parse

## Verify the project
##
cs886-check: $(SOURCES)
	${MAKE} -C src DAFNY=$(DAFNY) cs886-check

## Audit the project
##
cs886-audit: $(SOURCES)
	${MAKE} -C src DAFNY=$(DAFNY) cs886-audit

## Build an executable
##
cs886: $(SOURCES)
	mkdir -p ${BUILDDIR}
	${MAKE} -C src DAFNY=${DAFNY} TARGET=${TARGET_OUT} cs886

# -- [ Testing ]

.PHONY: cs886-test-build cs886-test-run cs886-test-run-re cs886-test-update

## Build the test suite.
##
cs886-test-build:
	${MAKE} -C tests testbin IDRIS2=$(IDRIS2)

## Run the test suite
##
cs886-test-run:
	echo ${TARGET}
	${MAKE} -C tests test \
			 IDRIS2=$(IDRIS2) \
			 PROG_BIN=$(TARGET) \
			 UPDATE='' \
			 ONLY=$(ONLY)

## Rerun failing tests.
##
cs886-test-run-re:
	${MAKE} -C tests test-re \
			 IDRIS2=$(IDRIS2) \
			 PROG_BIN=$(TARGET) \
			 ONLY=$(ONLY)

## update the test suite's expected answers with the output of test runs.
##
## YOU WILL NOT NEED TO INVOKE THIS.
##
cs886-test-update:
	${MAKE} -C tests test \
			 IDRIS2=$(IDRIS2) \
			 PROG_BIN=$(TARGET) \
			 THREADS=1 \
			 ONLY=$(ONLY)

## Generate a submission to upload to MyPlace

.PHONY: submission

submission:
	git archive --format=tar.gz --prefix=$(CWORK)-$(REGNO)/ -o $(CWORK)-$(REGNO).tgz HEAD .

## Cleaning the project of build files.

.PHONY: clobber clean

clean:
	rm -rf ${BUILDDIR}
	${MAKE} -C tests clean

clobber: clean
	${MAKE} -C tests clobber

# -- [ EOF ]
