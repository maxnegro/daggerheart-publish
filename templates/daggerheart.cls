\NeedsTeXFormat{LaTeX2e}
\ProvidesClass{daggerheart}[2026/02/11 Custom document class]

% --------------------
% Base class
% --------------------
\LoadClass[11pt,a4paper, twoside]{article}

% --------------------
% Required packages
% --------------------
\RequirePackage[a4paper,margin=1.6cm,includefoot]{geometry}
\RequirePackage{setspace}
\RequirePackage{amsmath,amssymb}
\RequirePackage{graphicx}
\RequirePackage{fancyhdr}
\RequirePackage{tabularx}
\RequirePackage{multicol}
\RequirePackage{fontspec}
\RequirePackage{framed}
\RequirePackage[table]{xcolor}
\RequirePackage[most]{tcolorbox}
\RequirePackage{titlesec}
\RequirePackage{parskip}
\RequirePackage{enumitem}
\RequirePackage{quoting}
\RequirePackage[colorlinks=true, linkcolor=darkgray]{hyperref}
\RequirePackage{needspace}
\RequirePackage{textcase}
\RequirePackage{tabulary}
\RequirePackage{array}
\RequirePackage{cuted}
\RequirePackage{etoolbox}
\RequirePackage{tikzpagenodes}
\RequirePackage{eso-pic}
\usetikzlibrary{calc,fadings}
\tikzfading[name=dgh fade to white,
	top color=transparent!100,
	bottom color=transparent!0]

\tikzfading[name=fadeToBg,
	top color=transparent!100,   % completamente trasparente
	bottom color=transparent!0]  % completamente opaco


% Distance from physical paper top to text body top (computed at begin-document)
\newlength{\dghpagetotext}
% Image height and title offset for sectionwithbg.
\newlength{\dghsectionbgheight}
\newlength{\dghsectionbgraise}
\newlength{\dghsectionbgbleed}
\newlength{\dghsectionbgfadeoffset}
\setlength{\dghsectionbgheight}{150pt}
\setlength{\dghsectionbgraise}{-18pt}
\setlength{\dghsectionbgbleed}{1bp}
% Default fade start (distance from page top): height - 80pt
% Override manually if needed; recomputed whenever height or raise changes.
\setlength{\dghsectionbgfadeoffset}{\dimexpr\dghsectionbgheight-80pt\relax}
\AtBeginDocument{%
	\setlength{\dghpagetotext}{1in}%
	\addtolength{\dghpagetotext}{\voffset}%
	\addtolength{\dghpagetotext}{\topmargin}%
	\addtolength{\dghpagetotext}{\headheight}%
	\addtolength{\dghpagetotext}{\headsep}%
}

% --------------------
% Page style
% --------------------
\pagestyle{fancy}
\fancyhf{}


\renewcommand{\headrulewidth}{0pt}
\renewcommand{\footrulewidth}{2pt}
\renewcommand{\footrule}{\hbox to \headwidth{\color{gold}\leaders\hrule height \footrulewidth\hfill}}

\fancyfoot[LE]{
	\fontsize{6pt}{12pt}\selectfont{
	\makebox[0pt][l]{
		\colorbox{gold}{
			\textbf{\quad\thepage\quad}
		}
		\enspace
		\textbf{
			%@title%\quad\leftmark\quad\rightmark
			\@title\text{:}\enspace\nouppercase\leftmark
		}
	}}
}

\fancyfoot[RO]{
	\fontsize{6pt}{12pt}\selectfont{
	\makebox[0pt][r]{
		\textbf{
			%\@title%\quad\leftmark\quad\rightmark
			\@title\text{:}\enspace\nouppercase\leftmark
		}
		\enspace
		\colorbox{gold}{
			\textbf{\quad\thepage\quad}
		}
		
	}}
}

\onehalfspacing
\setlength{\columnsep}{1.5em}

% --- Fonts ---
\renewcommand{\normalsize}{\fontsize{8.5}{10}\selectfont}
\normalsize
\renewcommand{\baselinestretch}{1.2}
\setmainfont{Montserrat-Regular.ttf}[
Path = ./fonts/,
ItalicFont = Merriweather-Italic.ttf,
BoldFont = Montserrat-SemiBold.ttf,
BoldItalicFont = Merriweather-BoldItalic.ttf
]
\newfontfamily\montserratThin{Montserrat-Thin.ttf}[
Path = ./fonts/,
]
\newfontfamily\montserratLight{Montserrat-Light.ttf}[
Path = ./fonts/,
]
\newfontfamily\eveleth{LeagueSpartan-Extrabold.ttf}[Path=./fonts/]

% --- Colors ---
\definecolor{maintext}{HTML}{000000}
\definecolor{h1text}{HTML}{444444}
\definecolor{h2text}{HTML}{3a6b7b}
\definecolor{h3text}{HTML}{927421}
\definecolor{h4text}{HTML}{3a6b7b}
\definecolor{h4square}{HTML}{deb334}
\definecolor{tableheaderbg}{HTML}{3a6b7b}
\definecolor{tablerow}{HTML}{ebf0f1}
\definecolor{white}{HTML}{ffffff}
\definecolor{squareboxbg}{HTML}{f1ebf4}
\definecolor{squareboxborder}{HTML}{4d2d63}
\definecolor{roundedboxbg}{HTML}{dde2ed}
\definecolor{quoteborder}{HTML}{deb334}
\definecolor{adversarybordercolor}{HTML}{bcab84}
\definecolor{adversarybgcolor}{HTML}{f4f0e5}
\definecolor{environmentbordercolor}{HTML}{a3a3a3}
\definecolor{environmentbgcolor}{HTML}{ededed}

% Daggerheart colours
\definecolor{gold}{HTML}{e4bd6b}

\definecolor{dg-red}{HTML}{7a1e1f}
\definecolor{dg-darkgreen}{HTML}{56673d}
\definecolor{dg-orange}{HTML}{ae5825}
\definecolor{dg-purple}{HTML}{754084}

\color{maintext}

% --- Columns ---
\setlength{\parindent}{0pt}
\setlength{\parskip}{0.5em}


\newcommand{\setboxcolor}[1]{
	\colorlet{squareboxbg}{#1}
}
\newcommand{\resetboxcolor}{
	\definecolor{squareboxbg}{HTML}{f1ebf4}
	\definecolor{squareboxborder}{HTML}{4d2d63}
}

% --- Custom square box ---
\newtcolorbox{squarebox}{
	colback=squareboxbg,
	enhanced,
	frame hidden,
	borderline north={.75pt}{0pt}{squareboxborder},
	borderline south={.75pt}{0pt}{squareboxborder},
	left=.75em,
	right=.75em,
	top=.75em,
	bottom=.75em,
	before skip=2em,
	after skip=2em,
	sharp corners,
}

% --- Custom rounded box ---
\newtcolorbox{roundedbox}{
	colback=gray!7,
	enhanced,
	frame hidden,
	arc=6pt,
	left=.75em,
	right=.75em,
	top=.75em,
	bottom=.75em,
	before skip=2em,
	after skip=2em,
}

% --- Blockquote ---
\newtcolorbox{quotebox}{
	colback=white,
	enhanced,
	frame hidden,
	borderline west={2pt}{0pt}{quoteborder},
	left=1em,
	right=0em,
	top=0.2em,
	bottom=0.2em,
	before skip=1em,
	after skip=1em,
	sharp corners,
}
\renewenvironment{quote}
{\begin{quotebox}}
{\end{quotebox}}

\usepackage{tikz}
\usetikzlibrary{shadings}

\definecolor{sfondoCover}{HTML}{295369}
\definecolor{h1textlight}{HTML}{F5E6D3}

\newenvironment{framecoverpage}[5]{%
    % \newgeometry{margin=0pt, top=0pt, bottom=0pt, left=0pt, right=0pt}
    \pagecolor{sfondoCover}%
    \begin{titlepage}
	\ifstrempty{#5}{}{%
	\begin{tikzpicture}[remember picture,overlay]
		% Immagine alta metà pagina, ritagliata a 0.5\paperheight
		\begin{scope}
			\clip (current page.north west) rectangle ([yshift=-0.5\paperheight] current page.north east);
			\node[anchor=north, inner sep=0pt] at (current page.north) {
				\includegraphics[width=\paperwidth, keepaspectratio]{#5}
			};
		\end{scope}
		% Fading sugli ultimi 28pt (opacità variabile)
		\fill[sfondoCover, path fading=fadeToBg]
			([yshift=-0.5\paperheight+32pt] current page.north west)
			rectangle
			([yshift=-0.5\paperheight] current page.north east);
		% Maschera anti‑artefatto da 0.5pt (come nel tuo esempio)
		\fill[sfondoCover]
			([yshift=-0.5\paperheight-10pt] current page.north west)
			rectangle
			([yshift=-0.5\paperheight+0.5pt] current page.north east);
	\end{tikzpicture}
	}
    
	\ifnum\dghcoverimagecreditenabled>0\relax
		\begin{tikzpicture}[remember picture,overlay]
			\node[
				anchor=north east,
				xshift=-10pt,
				yshift=-10pt,
				inner sep=3pt,
				align=right,
				fill=black,
				fill opacity=0.40,
				text opacity=1,
				rounded corners=2pt
			] at (current page.north east) {%
				\ifnum\dghcoverimagetitleenabled>0\relax
					{\normalfont\fontsize{8pt}{7pt}\selectfont\bfseries\color{lightgray} \dghcoverimagetitle}%
				\fi
				\ifnum\dghcoverimageauthorenabled>0\relax
					\ifnum\dghcoverimagetitleenabled>0\relax\\[-3pt]\fi
					{\normalfont\fontsize{6pt}{5pt}\selectfont\itshape\color{lightgray} \dghcoverimageauthor}%
				\fi
			};
		\end{tikzpicture}
	\fi

	\vspace*{\dimexpr0.5\paperheight-\dghpagetotext-26pt\relax}
    
    {\montserratLight\fontsize{32pt}{34pt}\selectfont\raggedright\color{h1textlight}\MakeUppercase #1}
    \vspace{1em}
    
	{\normalfont\fontsize{10pt}{13pt}\selectfont\itshape\color{white}\setlength{\parindent}{0pt}\setlength{\parskip}{0.35em}\rightskip=0pt\relax #2\par}    
    {\normalfont\fontsize{8pt}{6pt}\selectfont\color{white} \dghlabeldesignedby{} #3}\par
	\vspace{0.5em}

    {\normalfont\color{white}%
    \ifnum#4>0%
    \bfseries\dghlabelcomplexity: 
      \foreach \dghci in {1,...,#4}{%
        \tikz[baseline=-0.5ex,inner sep=0pt]{\filldraw[white](0,0)circle(2.0pt);}\kern2pt%
      }%
    \fi}\par
    % \vspace{1em}
    
	\begingroup
	\color{white}
	\setlength{\parindent}{1em}
	\setlength{\parskip}{0.25em}
	\renewcommand{\section}[1]{%
		\needspace{6\baselineskip}%
		\vspace{0.7em}%
		{\noindent\montserratLight\fontsize{13pt}{14pt}\selectfont\color{white}\MakeTextUppercase{##1}\par}%
		\nopagebreak[4]%
		\vspace{0.25em}%
	}
	\renewcommand{\subsection}[1]{%
		\needspace{5\baselineskip}%
		\vspace{0.5em}%
		{\noindent\eveleth\fontsize{11pt}{12pt}\selectfont\color{white}\MakeTextUppercase{##1}\par}%
		\nopagebreak[4]%
		\vspace{0.2em}%
	}
	\renewcommand{\subsubsection}[1]{%
		\needspace{4\baselineskip}%
		\vspace{0.4em}%
		{\noindent\bfseries\fontsize{9pt}{10pt}\selectfont\color{white}\MakeTextUppercase{##1}\par}%
		\nopagebreak[4]%
		\vspace{0.15em}%
	}
	\renewcommand{\paragraph}[1]{%
		\needspace{3\baselineskip}%
		\vspace{0.25em}%
		{\noindent\bfseries\fontsize{8.5pt}{9.5pt}\selectfont\color{white}##1\par}%
		\nopagebreak[4]%
	}
	\begin{multicols}{2}
	\raggedcolumns
}{%
	\end{multicols}
	\endgroup
	\vfill
	\end{titlepage}
	\nopagecolor
	\color{maintext}
	\pagestyle{fancy}
	\restoregeometry
}{}

% --- Titles ---
\setcounter{secnumdepth}{0}

\newif\ifdgresetsectioncoloronnextsection
\dgresetsectioncoloronnextsectionfalse

\newcommand{\dgsectioncolor}{h1text}
\newcommand{\dgsubsectioncolor}{h2text}

\newcommand{\applysectioncolor}[2]{%
	\titleformat{\section}
	{\montserratLight\fontsize{24pt}{24pt}\selectfont\color{#1}\raggedright\hyphenpenalty=10000\exhyphenpenalty=10000\MakeTextUppercase}
	{\thesection}
	{1em}
	{}
	\titleformat{\subsection}
	{\eveleth\fontsize{20pt}{20pt}\selectfont\color{#2}\raggedright\hyphenpenalty=10000\exhyphenpenalty=10000\MakeTextUppercase}
	{\thesubsection}
	{1em}
	{}
}

\newcommand{\setsectioncolor}[2]{%
	\global\def\dgsectioncolor{#1}%
	\global\def\dgsubsectioncolor{#2}%
	\applysectioncolor{\dgsectioncolor}{\dgsubsectioncolor}%
	\global\dgresetsectioncoloronnextsectiontrue
}

\newcommand{\setsubsubsectioncolor}[1]{%
	\titleformat{\subsubsection}
	{\bf\fontsize{15pt}{15pt}\selectfont\color{#1}\raggedright\hyphenpenalty=10000\exhyphenpenalty=10000\MakeTextUppercase}
	{\thesubsubsection}
	{1em}
	{}
}


\newcommand{\resetsectioncolor}{\global\def\dgsectioncolor{h1text}\global\def\dgsubsectioncolor{h2text}\applysectioncolor{\dgsectioncolor}{\dgsubsectioncolor} \setsubsubsectioncolor{h3text}\global\dgresetsectioncoloronnextsectionfalse}
\newcommand{\dgapplycurrentsectioncolor}{\applysectioncolor{\dgsectioncolor}{\dgsubsectioncolor}}
\resetsectioncolor

% Keep heading spacing deterministic: default article section skips include
% stretch/shrink components that can change layout based on remaining page content.
\titlespacing*{\section}{0pt}{0pt}{0.8em}
\titlespacing*{\subsection}{0pt}{1.0em}{0.5em}
\titlespacing*{\subsubsection}{0pt}{0.8em}{0.4em}

\titleformat{\paragraph}[hang]
	{\normalfont\normalsize\raggedright\hyphenpenalty=10000\exhyphenpenalty=10000\bfseries}
	{\theparagraph}{1em}{}
\titleformat{\subparagraph}[hang]
	{\normalfont\normalsize\raggedright\hyphenpenalty=10000\exhyphenpenalty=10000\bfseries\itshape}
	{\thesubparagraph}{1em}{}


\newcommand{\hfour}[1]{%
	\needspace{4\baselineskip}%
	\vspace*{3pt}%
	{\fontsize{10pt}{11pt}\selectfont\raggedright\hyphenpenalty=10000\exhyphenpenalty=10000\bfseries
		\raisebox{-0.1ex}{\textcolor{h4square}{\rule{1.5ex}{1.5ex}}}\hspace{0.45em}%
		\color{h4text} #1%
		\par}%
	\nopagebreak[4]%
	\vspace{3pt}%
}

\newif\ifdghonepagebreak
\dghonepagebreaktrue

\let\oldsection\section
\renewcommand{\section}[1]{%
	\ifindaggerfullpage
		\vspace{1em}%
		\ifdgresetsectioncoloronnextsection\resetsectioncolor\else\dgapplycurrentsectioncolor\fi
		\oldsection{#1}%
		\vspace{1em}%
	\else
		\end{multicols}%
		\ifdghonepagebreak\newpage\fi
		\vspace{1em}%
		\ifdgresetsectioncoloronnextsection\resetsectioncolor\else\dgapplycurrentsectioncolor\fi
		\oldsection{#1}%
		\vspace{1em}%
		\begin{multicols}{2}%
		\raggedcolumns
	\fi
}

\let\oldsubsection\subsection
\renewcommand{\subsection}[1]{%
	\dgapplycurrentsectioncolor
	\oldsubsection{#1}%
}

% --- Lists ---
\providecommand{\tightlist}{%
	\setlength{\itemsep}{0pt}\setlength{\parskip}{0pt}%
}
\setlength{\leftmargini}{1em}
\setlength{\leftmarginii}{1em}

% --- Frontpage ---
\newcommand{\dghtitleimagemode}{none}
\newcommand{\dghtitleimagepath}{}
\newcommand{\dghtitleimageheight}{0.5\paperheight}
\newcommand{\dghtitleimagefit}{fill}
\newcommand{\dghtitleimageposition}{middle}
\newcommand{\dghcovertitle}{}
\newcommand{\dghcoversubtitle}{}
\newcommand{\dghcoverdesigner}{}
\newcommand{\dghcovercomplexity}{0}
\newcommand{\dghcoverimagetitle}{}
\newcommand{\dghcoverimageauthor}{}
\newcommand{\dghcoverimagecreditenabled}{0}
\newcommand{\dghcoverimagetitleenabled}{0}
\newcommand{\dghcoverimageauthorenabled}{0}

\newcommand{\settitlepageimagemode}[1]{\gdef\dghtitleimagemode{#1}}
\newcommand{\settitlepageimagepath}[1]{\gdef\dghtitleimagepath{#1}}
\newcommand{\settitlepageimageheight}[1]{\gdef\dghtitleimageheight{#1}}
\newcommand{\settitlepageimagefit}[1]{\gdef\dghtitleimagefit{#1}}
\newcommand{\settitlepageimageposition}[1]{\gdef\dghtitleimageposition{#1}}

% Internal helper: inline image for half mode
\newcommand{\dghhalftitleimage}{%
	\includegraphics[width=0.85\paperwidth,height=\dghtitleimageheight,keepaspectratio]{\dghtitleimagepath}\\[2em]%
}

\newcommand{\frontpage}[4]{%
	\begin{titlepage}
		\ifdefempty{\dghtitleimagepath}{}{%
			\ifdefstring{\dghtitleimagemode}{background}{%
				\ifdefstring{\dghtitleimagefit}{contain}{%
					\AddToShipoutPictureBG*{%
						\AtPageLowerLeft{\includegraphics[width=\paperwidth,height=\paperheight,keepaspectratio]{\dghtitleimagepath}}%
					}%
				}{%
					\AddToShipoutPictureBG*{%
						\AtPageLowerLeft{\includegraphics[width=\paperwidth,height=\paperheight]{\dghtitleimagepath}}%
					}%
				}%
			}{}%
		}%
		\vspace*{\fill}
		\begin{center}
			% image above title (position=top)
			\ifdefempty{\dghtitleimagepath}{}{%
				\ifdefstring{\dghtitleimagemode}{half}{%
					\ifdefstring{\dghtitleimageposition}{top}{\dghhalftitleimage}{}%
				}{}%
			}%
			\vspace{62pt}
			{\eveleth\fontsize{36pt}{36pt}\selectfont\MakeTextUppercase{#1}}\\[1em]
			{\large\MakeUppercase{#2}}\\[2em]
			% image between subtitle and author (default, position=middle)
			\ifdefempty{\dghtitleimagepath}{}{%
				\ifdefstring{\dghtitleimagemode}{half}{%
					\ifdefstring{\dghtitleimageposition}{top}{}{\dghhalftitleimage}%
				}{}%
			}%
			\vspace{48pt}
			% authors block, then date on a separate line
			{\normalsize #3}%
			\ifblank{#4}{}{%
				\\[1em]%
				{\normalsize #4}%
			}%
		\end{center}
		\vspace*{\fill}
		\thispagestyle{empty}
	\end{titlepage}
}


\newcommand{\@subtitle}{}
\newcommand{\subtitle}[1]{\gdef\@subtitle{#1}}

\renewcommand{\maketitle}{
	\frontpage{\@title}{\@subtitle}{\@author}{\@date}
}

% --- Table of contents ---
\renewcommand{\tableofcontents}{%
	{\montserratThin\fontsize{24pt}{28pt}\selectfont\MakeTextUppercase{\contentsname}}%
	\@starttoc{toc}%
}
\makeatother

\tcbuselibrary{skins}

% --- Main Box ---
\newtcolorbox{adversarybox}[1]{
	enhanced,
	colback=adversarybgcolor,
	colframe=adversarybordercolor,
	arc=5pt,
	boxrule=1pt,
	outer arc=5pt,
	before skip=2em,
	after skip=2em,
	top=8pt,
	left=8pt,
	right=8pt,
	bottom=8pt,
	before upper={\parskip=4pt},
}

% --- Inner box ---
\newtcolorbox{adversaryinnerbox}{
	colback=white,
	enhanced,
	frame hidden,
	borderline north={1pt}{0pt}{adversarybordercolor},
	borderline south={1pt}{0pt}{adversarybordercolor},
	left=0.5em,
	right=0.5em,
	top=0.5em,
	bottom=0.5em,
	before skip=1em,
	after skip=1em,
	sharp corners,
}

\newcommand{\dghsectionseparator}{\par\noindent\rule{\linewidth}{1pt}\par}

% Macro per Tier+Type localizzata (definizioni separate per lingua)
\newcommand{\dghenvironmenttiertypeenglish}[2]{\dghlabeltier\ #1 #2}
\newcommand{\dghenvironmenttiertypeitalian}[2]{#2 di \dghlabeltier\ #1}
% Macro attiva (default inglese)
\newcommand{\dghenvironmenttiertype}[2]{\dghenvironmenttiertypeenglish{#1}{#2}}

% Localized labels (default English). If babel is loaded, labels switch with language.
\newcommand{\dghsetlabelsenglish}{%
	\let\dghenvironmenttiertype\dghenvironmenttiertypeenglish
	\gdef\dghlabeltier{Tier}%
	\gdef\dghlabelsize{Size}%
	\gdef\dghlabelsegments{Segments}%
	\gdef\dghlabeldifficulty{Difficulty}%
	\gdef\dghlabelthresholds{Thresholds}%
	\gdef\dghlabelhp{HP}%
	\gdef\dghlabelstress{Stress}%
	\gdef\dghlabelatk{ATK}%
	\gdef\dghlabelweapon{Weapon}%
	\gdef\dghlabelexperience{Experience}%
	\gdef\dghlabelmotivesandtactics{Motives \& Tactics}%
	\gdef\dghlabeladjacentsegments{Adjacent Segments}%
	\gdef\dghlabelfeatures{Features}%
	\gdef\dghlabelimpulses{Impulses}%
	\gdef\dghlabelpotentialadversaries{Potential Adversaries}%
	\gdef\dghlabeldesignedby{Designed by}%
	\gdef\dghlabelcomplexity{Complexity rating}%
}

\newcommand{\dghsetlabelsitalian}{%
	\let\dghenvironmenttiertype\dghenvironmenttiertypeitalian
	\gdef\dghlabeltier{Rango}%
	\gdef\dghlabelsize{Dimensioni}%
	\gdef\dghlabelsegments{Segmenti}%
	\gdef\dghlabeldifficulty{Difficoltà}%
	\gdef\dghlabelthresholds{Soglie}%
	\gdef\dghlabelhp{PF}%
	\gdef\dghlabelstress{Stress}%
	\gdef\dghlabelatk{ATT}%
	\gdef\dghlabelweapon{Arma}%
	\gdef\dghlabelexperience{Esperienza}%
	\gdef\dghlabelmotivesandtactics{Motivazioni e Tattiche}%
	\gdef\dghlabeladjacentsegments{Segmenti Adiacenti}%
	\gdef\dghlabelfeatures{Caratteristiche}%
	\gdef\dghlabelimpulses{Impeti}%
	\gdef\dghlabelpotentialadversaries{Potenziali Avversari}%
	\gdef\dghlabeldesignedby{Progettato da}%
	\gdef\dghlabelcomplexity{Livello di Complessit\`a}%
}

\dghsetlabelsenglish

\makeatletter
\AtBeginDocument{%
\@ifpackageloaded{babel}{%
\addto\captionsenglish{\dghsetlabelsenglish}%
\addto\captionsitalian{\dghsetlabelsitalian}%
\ifcsname languagename\endcsname
\ifdefstring{\languagename}{italian}{\dghsetlabelsitalian}{\dghsetlabelsenglish}%
\else
\dghsetlabelsenglish
\fi
}{}%
}
\makeatother


\newcommand{\dghexperienceseparator}{\noindent\rule{\linewidth}{0.25pt}}

\newcommand{\dghformatadjacentsegments}[1]{\textbf{\dghlabeladjacentsegments:}\ \mdseries\upshape #1}


\newcommand{\adversarystats}[9]{
	\ifstrempty{#1}{}{\textbf{\dghlabelsize:} #1\\}
	\ifstrempty{#2}{}{\textbf{\dghlabelsegments:} #2\\}
	\ifstrempty{#3}{}{\textbf{\dghlabeldifficulty:} #3 |}
	\ifstrempty{#4}{}{\textbf{\dghlabelthresholds:} #4 |}
	\ifstrempty{#5}{}{\textbf{\dghlabelhp:} #5 |}
	\ifstrempty{#6}{}{\textbf{\dghlabelstress:} #6}
	\ifstrempty{#7}{}{\\}
	\ifstrempty{#7}{}{\textbf{\dghlabelatk:} #7 	|}
	\ifstrempty{#8}{}{\textbf{#8:} #9}
}


\newcommand{\adversary}[6]{%
	\begin{adversarybox}{}%
		{\color{maintext}%
			\eveleth\fontsize{14pt}{14pt}\selectfont\MakeTextUppercase{#1}
			\par\smallskip
			\normalfont\fontsize{8pt}{8pt}\selectfont
			
			\ifstrempty{#2}{}{
				\textbf{\emph{#2}}
				\\%\par\smallskip
			}
			\ifstrempty{#3}{}{
				\emph{#3}
				\par%\smallskip
			}
			\ifstrempty{#4}{}{
				\textbf{\dghlabelmotivesandtactics:} #4
				\par%\smallskip
			}
			\ifstrempty{#5}{}{
				\begin{adversaryinnerbox}
					#5
				\end{adversaryinnerbox}
			}
			\par\smallskip
			
			\ifstrempty{#6}{}{			
				\eveleth\fontsize{12pt}{10pt}\selectfont\MakeTextUppercase{\dghlabelfeatures}
				\normalfont\fontsize{8pt}{8pt}\selectfont
				
				#6
			}
		}%
	\end{adversarybox}%
}

\newcommand{\colossusadversary}[6]{%
	\begin{environmentbox}{}%
		{\color{maintext}%
			\eveleth\fontsize{14pt}{14pt}\selectfont\MakeTextUppercase{#1}
			\par\smallskip
			\normalfont\fontsize{8pt}{8pt}\selectfont

			\ifstrempty{#2}{}{
				\textbf{\emph{#2}}
				\\%\par%\smallskip
			}
			\ifstrempty{#3}{}{
				\emph{#3}
				\par%\smallskip
			}
			\ifstrempty{#4}{}{
				\textbf{\dghlabelmotivesandtactics:} #4
				\par%\smallskip
			}
			\ifstrempty{#5}{}{
				\begin{environmentinnerbox}
					#5
				\end{environmentinnerbox}
			}
			\par\smallskip

			\ifstrempty{#6}{}{
				\eveleth\fontsize{12pt}{10pt}\selectfont\MakeTextUppercase{\dghlabelfeatures}
				\normalfont\fontsize{8pt}{8pt}\selectfont

				#6
			}
		}%
	\end{environmentbox}%
}

% --- Main Box ---
\newtcolorbox{environmentbox}[1]{
	enhanced,
	colback=environmentbgcolor,
	colframe=environmentbordercolor,
	arc=5pt,
	boxrule=1pt,
	outer arc=5pt,
	before skip=2em,
	after skip=2em,
	top=8pt,
	left=8pt,
	right=8pt,
	bottom=8pt,
	before upper={\parskip=4pt},
}

% --- Inner box ---
\newtcolorbox{environmentinnerbox}{
	colback=white,
	enhanced,
	frame hidden,
	borderline north={1pt}{0pt}{environmentbordercolor},
	borderline south={1pt}{0pt}{environmentbordercolor},
	left=0.5em,
	right=0.5em,
	top=0.5em,
	bottom=0.5em,
	before skip=1em,
	after skip=1em,
	sharp corners,
}

\newcommand{\environmentstats}[2]{
	\ifstrempty{#1}{}{\textbf{\dghlabeldifficulty:} #1 \ifstrempty{#2}{}{\\}}
	\ifstrempty{#2}{}{\textbf{\dghlabelpotentialadversaries:} #2}
}

\newcommand{\environment}[6]{%
	\begin{environmentbox}{}%
		{\color{maintext}%
			\eveleth\fontsize{14pt}{14pt}\selectfont\MakeTextUppercase{#1}
			\par\smallskip
			\normalfont\fontsize{8pt}{8pt}\selectfont
			
			\ifstrempty{#2}{}{
				\textbf{\emph{#2}}
				\\%\par\smallskip
			}
			\ifstrempty{#3}{}{
				\emph{#3}
				\par%\smallskip
			}
			\ifstrempty{#4}{}{
				\textbf{\dghlabelimpulses:} #4
				\par%\smallskip
			}
			\ifstrempty{#5}{}{
				\begin{environmentinnerbox}
					#5
				\end{environmentinnerbox}
			}
			\par%\smallskip
			
			\ifstrempty{#6}{}{
			\eveleth\fontsize{12pt}{10pt}\selectfont\MakeTextUppercase{\dghlabelfeatures}
			\normalfont\fontsize{8pt}{8pt}\selectfont
			
			#6
			}
		}%
	\end{environmentbox}%
}


\newif\ifindaggerfullpage
\indaggerfullpagefalse

\newcommand{\fullpage}[1]{
	\end{multicols}
	\indaggerfullpagetrue
	#1
	\indaggerfullpagefalse
	\begin{multicols}{2}
	\raggedcolumns
}

\newcommand{\beginFullpage}{%
	\end{multicols}%
	\indaggerfullpagetrue%
}
\newcommand{\finishFullpage}{%
	\indaggerfullpagefalse%
	\begin{multicols}{2}%
	\raggedcolumns%
}

% Force a real page break even when the document body is in multicols.
\newcommand{\dghpagebreak}{%
	\ifindaggerfullpage
		\newpage%
	\else
		\end{multicols}%
		\newpage%
		\begin{multicols}{2}%
		\raggedcolumns%
	\fi
}

% --- Section with background image ---
% Internal: renders image anchored at physical page top, full paper width,
% with a white fade over the bottom half of the image.
\newcommand{\dghsectionbgpicture}[1]{%
	\begin{tikzpicture}[remember picture, overlay]
		\begin{scope}
			\clip
				($(current page.north west) + (-\dghsectionbgbleed, \dghsectionbgbleed)$)
				rectangle
				($(current page.north east) + (\dghsectionbgbleed, -\dghsectionbgheight)$);
			\node[anchor=north west, inner sep=0pt] at ($(current page.north west) + (-\dghsectionbgbleed, \dghsectionbgbleed)$) {%
				\includegraphics[width=\dimexpr\paperwidth+2\dghsectionbgbleed\relax]{\detokenize{#1}}%
			};
		\end{scope}
		% white fade: starts at (height+raise) from page top, ends at image bottom
		\fill[white, path fading=dgh fade to white]
			% ($(current page.north west) + (-\dghsectionbgbleed, -126pt+\dghsectionbgbleed)$)
			($(current page.north west) + (-\dghsectionbgbleed, -\dghsectionbgfadeoffset)$)
			rectangle
			($(current page.north east) + (\dghsectionbgbleed, -\dghsectionbgheight)$);
		% anti-seam mask: hides 1px raster antialiasing at the south clip boundary
		\fill[white]
			($(current page.north west) + (-\dghsectionbgbleed, -\dghsectionbgheight+0.5bp)$)
			rectangle
			($(current page.north east) + (\dghsectionbgbleed, -\dghsectionbgheight-0.5bp)$);
	\end{tikzpicture}%
}

% \sectionwithbg{imagepath}{title}: h1 with background image.
% Image is placed at paper top; h1 cap-top aligns with image bottom.
% Optionally set \dghsectionbgheight before calling to control image height.
\newcommand{\dghsectionbgrender}[2]{%
	\dghsectionbgpicture{#1}%
	\ifdgresetsectioncoloronnextsection\resetsectioncolor\else\dgapplycurrentsectioncolor\fi
	\vspace*{\dimexpr\dghsectionbgheight-\dghpagetotext+\dghsectionbgraise\relax}%
	\oldsection{#2}%
}

\newcommand{\sectionwithbg}[2]{%
	\ifindaggerfullpage
		\dghsectionbgrender{#1}{#2}%
	\else
		\end{multicols}%
		\ifdghonepagebreak\newpage\fi
		\dghsectionbgrender{#1}{#2}%
		\begin{multicols}{2}%
		\raggedcolumns%
	\fi
}

\newcommand{\ColoredTable}[4]{%
	\renewcommand{\arraystretch}{1.3}
	\rowcolors{2}{#2!20}{white}
	\begin{tabularx}{#1}{#3}
		\rowcolor{#2}
		#4
	\end{tabularx}
}

