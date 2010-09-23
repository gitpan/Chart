all: clean Documentation.pdf

pdf: Documentation.pdf

Documentation.pdf: Documentation.tex
	pdflatex Documentation.tex
	makeindex Documentation.idx
	pdflatex Documentation.tex
	@latex_count=5 ; \
	while egrep -s 'Rerun (LaTeX|to get cross-references right)' Documentation.log && [ $$latex_count -gt 0 ] ;\
	    do \
	      echo "Rerunning latex...." ;\
	      pdflatex Documentation.tex ;\
	      latex_count=`expr $$latex_count - 1` ;\
	    done; \
	cp -p Documentation.pdf ../..


clean:
	rm -f *.ps *.dvi *.aux *.toc *.idx *.ind *.ilg *.log *.out Documentation.pdf
