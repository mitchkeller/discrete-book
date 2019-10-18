## This file is part of the book                 ##
##                                               ##
##   Discrete Mathematics: An Open Introduction  ##
##                                               ##
## Copyright (C) 2015-2018  Oscar Levin          ##
## See the file COPYING for copying conditions.  ##

## Based on the corresponding file from          ##
##  Abstract Algebra: Theory and Applications    ##
##  by Tom Judson                                ##

#######################
# DO NOT EDIT THIS FILE
#######################

#   1) Do make a copy of Makefile.paths.original
#      as Makefile.paths
#   2) Edit Makefile.paths to provide full paths to the root folders
#      of your local clones of the project repository and the mathbook
#      repository as described below.
#   3) The files Makefile and Makefile.paths.original
#      are managed by git revision control and any edits you make to
#      these will conflict. You should only be editing Makefile.paths.

##############
# Introduction
##############

# This is not a "true" makefile, since it does not
# operate on dependencies.  It is more of a shell
# script, sharing common configurations

# This is mostly offered as an example of one approach
# to managing a project with multiple output formats. and
# is not claimed to be "best practice"

######################
# System Prerequisites
######################

#   install         (system tool to make directories)
#   xsltproc        (xml/xsl text processor)
#   tar             (to package SageMathCloud worksheets for upload)
#   xmllint         (only to check source against DTD)
#   <helpers>       (PDF viewer, web browser, pager, Sage executable, etc)

#####
# Use
#####

#	A) Set default directory to be the location of this file
#	B) At command line:  make solutions  (and employ targets)



# The included file contains customized versions
# of locations of the principal components of this
# project and names of various helper executables
include Makefile.paths

# This is to ensure that latex is not skipped
.PHONY: latex html


# These paths are subdirectories of
# the Mathbook XML distribution
# MBUSR is where extension files get copied
# so relative paths work properly
PTXXSL = $(PTX)/xsl
PTXSCRIPT = $(PTX)/script
PTXUSR = $(PTX)/user
PTXRELAXNG = $(PTX)/schema

# These are source and custom XSL subdirectories
# for the two DMOI repositories
SRC = $(DMOI)/ptx
XSL = $(DMOI)/xsl

# These are the files to apply templates to
MAIN = $(SRC)/dmoi.ptx
MERGED = $(LOCALBUILD)/dmoi-merge.ptx

# These paths are subdirectories of
# a scratch directory
HTMLOUT    = $(SCRATCH)/html
PDFOUT     = $(SCRATCH)/latex
SMCOUT     = $(SCRATCH)/dmoi-smc
DOCTEST    = $(SCRATCH)/doctest
EPUBOUT    = $(SCRATCH)/epub
SAGENBOUT  = $(SCRATCH)/sagenb
JUPYTEROUT = $(SCRATCH)/jupyter
LOCALBUILD = $(SCRATCH)/localbuild

# Some aspects of producing these examples require a WeBWorK server.
# Either specify only the protocol and domain (like https://webwork.yourschool.edu)
# or specify a 5-tuple with quotes exactly as in this example
# SERVER = "(https://webwork-ptx.aimath.org,courseID,userID,password,course_password)"
SERVER = https://webwork-dev.aimath.org

# Following regularly presumes  xml:id="dmoi" on
# the <book> element, so xsltproc creates  dmoi.tex

###############
# Preliminaries
###############

# Diagrams
#   invoke mbx script to manufacture diagrams
#   tikz as SVG for HTML
#   sageplot as PDF for LaTeX, SVG for HTML
#   these outputs are in source repo now, and
#   are typically just copied out
#   this should be run if diagram source changes
#   NB: targets below copy versions out of repo and clobber these
diagrams:
	install -d $(HTMLOUT)/images
	-rm $(HTMLOUT)/images/*.svg
	$(PTXSCRIPT)/mbx -v -c latex-image -f svg -d $(HTMLOUT)/images $(MAIN)
	# $(PTXSCRIPT)/mbx -v -c sageplot    -f pdf -d $(HTMLOUT)/images $(MAIN)
	# $(PTXSCRIPT)/mbx -v -c sageplot    -f svg -d $(HTMLOUT)/images $(MAIN)

# WeBWorK extraction
#   This happens in two steps (for now), first extract WW problems into a single xml file called webwork-extraction.xml in localbuild, which holds multiple versions of each problem.

ww-extraction:
	install -d $(LOCALBUILD)
	-rm $(LOCALBUILD)/webwork-extraction.xml
	$(PTXSCRIPT)/mbx -v -c webwork -d $(LOCALBUILD) -s $(SERVER) $(MAIN)
	sed -i.bak 's/label="a."/label="(a)"/g' $(LOCALBUILD)/webwork-extraction.xml
	rm $(LOCALBUILD)/webwork-extraction.xml.bak

# 	Then we merge this with the main source 

ww-merge:
	cd $(SCRATCH); \
	xsltproc --xinclude --stringparam webwork.extraction $(LOCALBUILD)/webwork-extraction.xml $(PTXXSL)/pretext-merge.xsl $(MAIN) > $(LOCALBUILD)/dmoi-merge.ptx

ww-fresh: ww-extraction ww-merge



##########
# Products
##########

# HTML version
#   Copies in image files from source directory
#   Move to server: generated *.html and
#   entire directories - /images and /knowl
html: ww-merge
	install -d $(HTMLOUT)
	-rm $(HTMLOUT)/*.html
	-rm $(HTMLOUT)/knowl/*.html
	cp -a images $(HTMLOUT)
	cd $(HTMLOUT); \
	xsltproc --xinclude $(XSL)/custom-html.xsl $(MERGED);

html-fresh: diagrams ww-extraction html

viewhtml:
	$(HTMLVIEWER) $(HTMLOUT)/dmoi.html &

# Full PDF version
#   copies in all image files, which is overkill (SVG's)
#   produces  aata-sage.tex  in scratch directory
#   which becomes PDF, along with index entries
#   Includes *all* material, and is fully electronic
#   This is the DMOI/Sage downloadable Annual Edition
# sage:
# 	# delete old  xsltproc  output
# 	# dash prevents error if not found
# 	-rm $(PDFOUT)/aata.tex
# 	install -d $(PDFOUT) $(MBUSR)
# 	cp -a $(SRC)/images $(PDFOUT)
# 	cp $(XSL)/aata-common.xsl $(XSL)/aata-latex.xsl $(XSL)/aata-sage.xsl $(MBUSR)
# 	cd $(PDFOUT); \
# 	xsltproc --xinclude $(MBUSR)/aata-sage.xsl $(SRC)/dmoi.ptx; \
# 	$(ENGINE) aata.tex; $(ENGINE) aata.tex; \
# 	mv aata.pdf aata-sage.pdf
# 
# # View PDF from correct directory
# viewsage:
# 	$(PDFVIEWER) $(PDFOUT)/aata-sage.pdf &


# Print PDF version
#   A print version for print-on-demand
#   This will be source for the Annual Edition,
#     as sent to Orthogonal Publishing for modification
#   Black on white, no live URLs, etc
#   This is the "printable" downloadable Annual Edition
latex: ww-merge
	-rm $(PDFOUT)/dmoi.tex
	install -d $(PDFOUT)
	cp -a images $(PDFOUT)
	cd $(PDFOUT); \
	xsltproc --xinclude $(XSL)/custom-latex.xsl $(MERGED) > dmoi.tex;

latex-fresh: ww-extraction latex
	
pdf:
	cd $(PDFOUT); \
	$(ENGINE) dmoi.tex;

print: latex
	cd $(PDFOUT); \
	$(ENGINE) dmoi.tex; $(ENGINE) dmoi.tex; \
	mv dmoi.pdf dmoi-print.pdf

	# View PDF from correct directory
viewpdf:
	$(PDFVIEWER) $(PDFOUT)/dmoi.pdf
	
viewprint:
	$(PDFVIEWER) $(PDFOUT)/dmoi-print.pdf
	
# Electronic PDF version
#   copies in all image files, which is overkill (SVG's)
#   produces  aata-electronic.tex  in scratch directory
#   which becomes PDF, along with index entries
#   Similar to "print" but with links, etc.
#   No Sage material
#   This is default downloadable Annual Edition
#   ie, aata-YYYYMMDD.pdf in repository download section
latex-tablet:
	-rm $(PDFOUT)/dmoi.tex
	install -d $(PDFOUT)
	# cp -a images $(PDFOUT)
	cd $(PDFOUT); \
	xsltproc --xinclude $(XSL)/custom-latex-tablet.xsl $(MERGED); \

tablet: latex-tablet
	cd $(PDFOUT); \
	$(ENGINE) dmoi.tex; $(ENGINE) dmoi.tex; \
	mv dmoi.pdf dmoi-tablet.pdf

# View PDF from correct directory
viewtablet:
	$(PDFVIEWER) $(PDFOUT)/dmoi-tablet.pdf &



# Author's Draft
#   Like electronic PDF version, but for:
#   No index created, since showidx is used
#   Various markup for author's use, todo's etc
draft:
	# delete old  xsltproc  output
	# dash prevents error if not found
	-rm $(PDFOUT)/aata.tex
	install -d $(PDFOUT) $(MBUSR)
	cp -a $(SRC)/images $(PDFOUT)
	cp $(XSL)/aata-common.xsl $(XSL)/aata-latex.xsl $(XSL)/aata-electronic.xsl $(MBUSR)
	cd $(PDFOUT); \
	xsltproc --xinclude --stringparam author-tools 'yes' \
	--stringparam latex.draft 'yes' $(MBUSR)/aata-electronic.xsl $(SRC)/dmoi.ptx; \
	$(ENGINE) aata.tex; $(ENGINE) aata.tex; \
	mv aata.pdf aata-draft.pdf

viewdraft:
	$(PDFVIEWER) $(PDFOUT)/aata-draft.pdf &


######
# Sage
######

# DMOI has extensive support for Sage
# These targets are all related to that

# Doctest
#   All Sage material, but not solutions to exercises
#   Prepare location, remove *.py from previous runs
#   XSL dumps into current directory, Sage processes whole directory
#   chunk level 2 gives sections (commentaries, exercises)
doctest:
	-rm $(DOCTEST)/*.py; \
	install -d $(DOCTEST)
	cd $(DOCTEST); \
	xsltproc --xinclude --stringparam chunk.level 2 $(MBXSL)/mathbook-sage-doctest.xsl $(SRC)/dmoi.ptx; \
	$(SAGE) -tp 0 .

# SageMathCloud worksheets
#   can upload, extract tarball
#   that has "aata-smc" as root directory
#     $ tar -xvf aata-smc.tgz
smc:
	install -d $(SMCOUT) $(MBUSR)
	cp -a $(SRC)/images $(SMCOUT)
	cp -a $(MB)/css/mathbook-content.css $(MB)/css/mathbook-add-on.css $(SMCOUT)
	cp $(XSL)/aata-common.xsl $(XSL)/aata-smc.xsl $(MBUSR)
	cd $(SMCOUT); \
	xsltproc --xinclude $(MBUSR)/aata-smc.xsl $(SRC)/dmoi.ptx
	# wrap up into a tarball in SCRATCH
	# NB: subdir must match with SMCOUT
	tar -c -z -f $(SCRATCH)/aata-smc.tgz -C $(SCRATCH) aata-smc

###########
# Utilities
###########

## Clean solutions for student version ##

cleansols:
	install -d $(SCRATCH)
	install -d $(SCRATCH)/ptx-clean
	install -d $(SCRATCH)/ptx-clean/exercises
	# -rm $(SCRATCH)/ptx-clean/*.ptx
	# # -rm $(SCRATCH)/ptx-clean/exercises/*.ptx
	# for f in ptx/*.ptx; do \
	# 	xsltproc -o ptx-clean/$${f##*/} xsl/clean-solutions.xsl $$f; \
	# done
	# $(foreach var,$(wildcard ptx/*.ptx), \
	# 	xsltproc -o ptx-clean/$(notdir $(var)) xsl/clean-solutions.xsl $(var);)
	$(foreach var,$(wildcard ptx/exercises/*.ptx), \
		xsltproc -o ptx-clean/exercises/$(notdir $(var)) xsl/clean-solutions.xsl $(var);)
	# xsltproc -o $(SCRATCH)/ptx-clean/ xsl/clean-solutions.xsl $(widcard $(DMOI)/ptx/*.ptx)
	# xsltproc xsl/clean-solutions.xsl $(widcard $(DMOI)/ptx/*.ptx)






## THESE NEED WORK ##

# Check document source against the DTD
#   Leaves "dtderrors.txt" in SCRATCH
#   can then grep on, eg
#     "element XXX:"
#     "does not follow"
#     "Element XXXX content does not follow"
#     "No declaration for"
#   Automatically invokes the "less" pager, could configure as $(PAGER)
check:
	install -d $(SCRATCH)
	-rm $(SCRATCH)/jing-errors.txt
	jing $(PTXRELAXNG)/pretext.rng $(MAIN) > jing-errors.txt
	
check-clean:
	sed -i '/attribute "permid"/d' ./jing-errors.txt
	# sed -i '/attribute "category"/d' ./jing-errors.txt
	sed -i '/attribute "oldpermid"/d' ./jing-errors.txt
	sed -i '/element "instruction"/d' ./jing-errors.txt
	sed -i '/element "var"/d' ./jing-errors.txt
	sed -i '/./G' ./jing-errors.txt

viewcheck:
	less $(SCRATCH)/dtderrors.txt

##############
# Experimental
##############

# These are in-progress and/or totally broken

# Jupyter Notebooks - experimental
jupyter:
	install -d $(JUPYTEROUT) $(MBUSR)
	cp -a $(SRC)/images $(JUPYTEROUT)
	cp $(XSL)/aata-common.xsl $(XSL)/aata-jupyter.xsl $(MBUSR)
	cd $(JUPYTEROUT); \
	xsltproc --xinclude $(MBUSR)/aata-jupyter.xsl $(SRC)/dmoi.ptx


# Sage Notebooks
#   Need to  make diagrams first (not a true makefile)
#   First, all content
#   Copy all the pieces into place relatice to $SCRATCH
#   Drop result in $SAGENBOUT
sagenb:
	install -d $(HTMLOUT)
	cp -a $(SRC)/*.xml $(SRC)/images $(SRC)/exercises $(SRC)/sage $(SCRATCH)
	cp -a $(HTMLOUT)/images $(SCRATCH)
	$(MBSCRIPT)/mbx -v -c all -f sagenb -o $(SAGENBOUT)/aata.zip $(SCRATCH)/dmoi.ptx

# This makes a zip file of a version for use at AIM Books
# Clean out directories first by hand
# Date and upload
# HTML version
#   Copies in image files from source directory
aimhtml:
	install -d $(HTMLOUT) $(MBUSR)
	cp -a $(SRC)/images $(HTMLOUT)
	cp $(XSL)/aata-common.xsl $(XSL)/aata-html.xsl $(MBUSR)
	sed -i -e 's/002637997310187229905:qj2oy0jlpyu/008832104071767086392:pxbnbrlbfwa/' $(SRC)/bookinfo.xml
	cd $(HTMLOUT); \
	xsltproc --xinclude --stringparam html.annotation hypothesis $(MBUSR)/aata-html.xsl $(SRC)/dmoi.ptx
	sed -i -e 's/008832104071767086392:pxbnbrlbfwa/002637997310187229905:qj2oy0jlpyu/' $(SRC)/bookinfo.xml
	mv $(SCRATCH)/html $(SCRATCH)/aata-html
	cd $(SCRATCH); \
	zip -r $(SCRATCH)/aata-html-2018-datehere.zip aata-html/


# EPUB 3.0 assembly
#	TODO: fix retrieval of CSS (via wget?)
epub:
	rm -rf $(EPUBOUT)
	install -d $(EPUBOUT) $(EPUBOUT)/EPUB/css $(EPUBOUT)/EPUB/xhtml
	cd $(EPUBOUT); \
	xsltproc --xinclude  $(MBXSL)/mathbook-epub.xsl $(SRC)/dmoi.ptx
	rm -rf $(EPUBOUT)/knowl
	cp ~/mathbook/local/epub-trial/mathbook-content.css $(EPUBOUT)/EPUB/css/
	cp -a $(SRC)/images $(EPUBOUT)/EPUB/xhtml
	cp -a $(EPUBOUT)/EPUB/xhtml/images/cover_aata_2014.png $(EPUBOUT)/EPUB/xhtml/images/cover.png
	#
	cp -a /media/rob/disk/mathjax-out/*.html $(EPUBOUT)/EPUB/xhtml
	#
	cd $(EPUBOUT); \
	zip -0Xq  aata-mathml.epub mimetype; zip -Xr9Dq aata-mathml.epub *
