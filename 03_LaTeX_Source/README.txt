Mal Customer 360 & CAR -- LaTeX source bundle
==============================================

Compile any deliverable with xelatex (fontspec + tcolorbox based; will not
compile correctly under plain pdflatex):

  cd doc1_architecture  && xelatex architecture.tex  && xelatex architecture.tex
  cd doc2_erd           && xelatex erd_document.tex  && xelatex erd_document.tex
  cd doc3_sql           && xelatex identity_sql.tex  && xelatex identity_sql.tex
  cd doc4_tradeoffs_qa  && xelatex tradeoffs_qa.tex   && xelatex tradeoffs_qa.tex
  cd doc5_defense_qa    && xelatex defense_qa.tex     && xelatex defense_qa.tex
  cd doc6_streaming_brief && xelatex streaming_brief.tex && xelatex streaming_brief.tex

If your editor doesn't compile with XeLaTeX by default (MiKTeX/TeXworks
and some VS Code + LaTeX Workshop setups default to pdfLaTeX), add
"% !TeX program = xelatex" as the very first line of whichever .tex file
you're compiling -- most editors read that magic comment and switch
engines automatically. Without it, or without selecting XeLaTeX
explicitly, compilation fails immediately: this preamble uses fontspec,
which pdfLaTeX cannot run.

(Run twice for correct table of contents / page references.)

FONTS -- no system install needed
----------------------------------
The fonts/ folder in this bundle contains the exact font files the
documents use (Liberation Serif, Liberation Sans, DejaVu Sans Mono).
mal-preamble.tex loads them by relative file path (../fonts/...), not by
querying your OS's installed fonts -- so there is nothing to install, on
any machine, on any OS. Keep the folder structure intact (fonts/ must
stay a sibling of mal-preamble.tex, one level above each doc*/ folder).

If you ever want to switch to your OS's own copies of these fonts instead,
or swap in different fonts entirely, edit the \defaultfontfeatures and the
\setmainfont / \newfontfamily / \setmonofont block near the top of
mal-preamble.tex.

PACKAGES
--------
Requires TeX Live or MiKTeX with fontspec, tcolorbox, listings, booktabs,
tabularx, fancyhdr, titlesec, xcolor, hyperref, enumitem, longtable,
colortbl, caption, geometry, parskip. MiKTeX with "install packages
on-the-fly" enabled will fetch these automatically on first compile --
no manual package installation required either.

doc2_erd/erd.pdf is the pre-rendered ERD figure (from erd.mmd via
mermaid-cli: mmdc -i erd.mmd -o erd.pdf -b white -s 3 -f). Re-render it if
the schema changes.
