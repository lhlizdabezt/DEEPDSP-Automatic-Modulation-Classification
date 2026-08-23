#import "../config.typ": *
#import "../facts.typ": facts

#let identity() = align(center)[
  #set par(first-line-indent: 0pt, justify: false, leading: 0.30em)
  #text(size: 12.8pt, weight: "bold")[#meta.university-top]
  #linebreak()
  #text(size: 12.8pt, weight: "bold")[#meta.university-name]
  #v(0.08cm)
  #text(size: 12.2pt, weight: "bold", fill: navy)[#meta.faculty-name]
]

#let course-band() = align(center)[
  #block(
    width: 13.2cm,
    inset: (x: 12pt, y: 8pt),
    fill: pale-blue,
    stroke: 0.8pt + navy,
    radius: 2pt,
  )[
    #set par(first-line-indent: 0pt, justify: false, leading: 0.27em)
    #align(center)[
      #text(size: 11.2pt, weight: "bold")[#meta.course-name]
      #v(2pt)
      #text(size: 10.5pt, weight: "bold", fill: blue)[LỚP #meta.class-name]
    ]
  ]
]

#let title-block() = align(center)[
  #set par(first-line-indent: 0pt, justify: false, leading: 0.27em)
  #text(size: 13.2pt, weight: "bold")[#meta.report-type]
  #v(0.30cm)
  #title-rule(width: 11.5cm)
  #v(0.34cm)
  #text(size: 18.2pt, weight: "bold", fill: navy)[NHẬN DẠNG ĐIỀU CHẾ SỐ TỰ ĐỘNG]
  #linebreak()
  #text(size: 18.2pt, weight: "bold", fill: navy)[TRONG KÊNH VÔ TUYẾN NHIỄU]
  #linebreak()
  #text(size: 16.4pt, weight: "bold")[BẰNG XỬ LÝ TÍN HIỆU SỐ VÀ HỌC SÂU]
  #v(0.25cm)
  #text(size: 11pt, weight: "bold", fill: cyan)[#meta.short-title]
  #v(0.18cm)
  #text(size: 10.4pt, style: "italic", fill: gray-4)[#meta.title-en]
  #v(0.32cm)
  #title-rule(width: 11.5cm)
]

#let people() = block(width: 100%)[
  #set par(first-line-indent: 0pt, justify: false, leading: 0.34em)
  #grid(
    columns: (4.25cm, 0.28cm, 1fr),
    row-gutter: 4pt,
    [#strong[Giảng viên]], [:], [#meta.lecturer],
    [#strong[Sinh viên thực hiện]], [:], [#meta.student],
    [#strong[Mã số sinh viên]], [:], [#meta.student-id],
  )
]

#let project-profile() = block(
  width: 100%,
  inset: (x: 12pt, y: 10pt),
  fill: gray-1,
  stroke: 0.65pt + ink,
  radius: 2pt,
)[
  #set text(size: 10.8pt)
  #set par(first-line-indent: 0pt, justify: false, leading: 0.30em)
  #grid(
    columns: (3.45cm, 0.25cm, 1fr),
    row-gutter: 4pt,
    [#strong[Đối tượng]], [:], [6 kiểu điều chế số; khung I/Q 256 mẫu],
    [#strong[Dải khảo sát]], [:], [SNR từ -12 dB đến 18 dB],
    [#strong[Mô hình]], [:], [Random Forest, CNN 1-D và tổ hợp xác suất],
    [#strong[Kết quả chính]],
    [:],
    [Hybrid macro-F1 #facts.hybrid-f1; đạt 90% accuracy từ #facts.hybrid-snr90],

    [#strong[Video demo]], [:], [#link(meta.video-url)[youtu.be/yl5Sk6plWXg]],
  )
]

#let outer-cover() = [
  #set page(numbering: none, footer: none)
  #rect(width: 100%, height: 100%, stroke: 2.3pt + navy, inset: 7pt)[
    #rect(width: 100%, height: 100%, stroke: 0.75pt + navy, inset: 16pt)[
      #identity()
      #v(0.40cm)
      #title-rule(width: 5cm)
      #v(0.48cm)
      #course-band()
      #v(0.70cm)
      #title-block()
      #v(0.80cm)
      #people()
      #v(1fr)
      #align(center)[
        #text(size: 11.5pt, weight: "bold")[#meta.city]
        #linebreak()
        #text(size: 11.5pt, weight: "bold")[#meta.date]
      ]
    ]
  ]
  #pagebreak()
]

#let inner-cover() = [
  #set page(numbering: none, footer: none)
  #identity()
  #v(0.32cm)
  #title-rule(width: 5cm)
  #v(0.45cm)
  #course-band()
  #v(0.58cm)
  #title-block()
  #v(0.58cm)
  #project-profile()
  #v(0.48cm)
  #people()
  #v(1fr)
  #align(center)[#text(size: 11.5pt, weight: "bold")[#meta.city — #meta.date]]
  #pagebreak()
]

#let cover-pages() = [
  #outer-cover()
  #inner-cover()
]
