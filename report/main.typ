#import "config.typ": *
#import "facts.typ": facts
#import "src/00_cover.typ": cover-pages
#import "src/01_front_matter.typ": (
  abbreviations-page, abstract-en-page, abstract-vi-page, commitment-page,
)
#import "@preview/codly:1.3.0": *
#import "@preview/codly-languages:0.1.10": *

#set document(
  title: meta.title-vi,
  author: meta.student,
  keywords: (
    "automatic modulation classification",
    "digital signal processing",
    "I/Q signal",
    "convolutional neural network",
    "wireless communication",
  ),
)

#set page(
  paper: "a4",
  margin: (top: 2cm, bottom: 2cm, left: 2.5cm, right: 2cm),
)

#set text(
  font: "Times New Roman",
  size: 13pt,
  lang: "vi",
  top-edge: 0.8em,
  bottom-edge: -0.2em,
)

#show: codly-init.with()
#codly(
  languages: codly-languages,
  stroke: 0.55pt + rgb("#71808D"),
  radius: 2pt,
  fill: luma(98%),
)

#show link: set text(fill: blue)
#show link: underline
#show ref: it => {
  if it.element == none { return it }
  set text(fill: blue)
  it
}
#show cite: it => {
  show regex("\\d+"): set text(fill: blue)
  it
}

#show raw.where(block: false): inline-code
#set figure(gap: 0.32em)
#set figure.caption(separator: [: ])
#show figure.caption: caption => [
  #set par(first-line-indent: 0pt, justify: true)
  #context text(size: 10.6pt)[
    #text(weight: "bold")[#caption.supplement #caption.counter.display(
        caption.numbering,
      )]#caption.separator#caption.body
  ]
  #v(0.08cm)
]

#set par(
  justify: true,
  leading: 0.58em,
  first-line-indent: (amount: 1.25cm, all: true),
)
#set math.equation(numbering: "(1)")
#set heading(numbering: "1.1.1")

#show heading.where(level: 1): it => [
  #pagebreak(weak: true)
  #v(0.03cm)
  #align(center)[#text(
    16pt,
    weight: "bold",
    fill: navy,
  )[CHƯƠNG #counter(heading).display()]]
  #v(0.08cm)
  #align(center)[#text(15pt, weight: "bold")[#it.body]]
  #v(0.10cm)
  #title-rule(width: 7cm)
  #v(0.18cm)
]

#show heading.where(level: 2): it => block(width: 100%, breakable: true)[
  #set par(first-line-indent: 0pt, justify: false)
  #v(0.08cm)
  #if it.numbering == none {
    text(13.5pt, weight: "bold", fill: navy)[#it.body]
  } else {
    text(
      13.5pt,
      weight: "bold",
      fill: navy,
    )[#counter(heading).display(). #it.body]
  }
  #v(0.03cm)
]

#show heading.where(level: 3): it => block(width: 100%, breakable: true)[
  #set par(first-line-indent: 0pt, justify: false)
  #v(0.04cm)
  #if it.numbering == none {
    text(13pt, weight: "bold", style: "italic")[#it.body]
  } else {
    text(
      13pt,
      weight: "bold",
      style: "italic",
    )[#counter(heading).display(). #it.body]
  }
  #v(0.02cm)
]

#cover-pages()

#set page(numbering: "i", footer: page-footer)
#counter(page).update(1)

#commitment-page()
#abstract-vi-page()
#abstract-en-page()

#unnumbered-chapter([MỤC LỤC])
#{
  set text(size: 10.4pt)
  set par(leading: 0.31em, first-line-indent: 0pt)
  outline(title: none, depth: 3)
}
#pagebreak()

#abbreviations-page()

#unnumbered-chapter([DANH SÁCH HÌNH])
#{
  set text(size: 10.5pt)
  set par(leading: 0.34em, first-line-indent: 0pt)
  outline(title: none, target: figure.where(kind: image))
}
#pagebreak()

#unnumbered-chapter([DANH SÁCH BẢNG])
#{
  set text(size: 10.5pt)
  set par(leading: 0.34em, first-line-indent: 0pt)
  outline(title: none, target: figure.where(kind: table))
}
#pagebreak()

#set page(numbering: "1", footer: page-footer)
#counter(page).update(1)
#counter(heading).update(0)

#include "src/02_introduction.typ"
#include "src/03_theory.typ"
#include "src/04_methodology.typ"
#include "src/05_implementation.typ"
#include "src/06_results.typ"
#include "src/07_conclusion.typ"

#pagebreak()
#unnumbered-chapter([TÀI LIỆU THAM KHẢO])
#{
  set text(size: 10.2pt)
  set par(leading: 0.33em, first-line-indent: 0pt)
  bibliography("references.bib", style: "ieee", title: none, full: true)
}

#include "src/08_appendices.typ"
