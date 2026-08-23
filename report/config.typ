#let meta = (
  university-top: "ĐẠI HỌC QUỐC GIA THÀNH PHỐ HỒ CHÍ MINH",
  university-name: "TRƯỜNG ĐẠI HỌC KHOA HỌC TỰ NHIÊN",
  faculty-name: "KHOA ĐIỆN TỬ - VIỄN THÔNG",
  course-name: "THỰC HÀNH XỬ LÝ TÍN HIỆU SỐ",
  class-name: "24DTV_DKD2",
  lecturer: "ThS. HUỲNH QUỐC THỊNH",
  student: "LƯƠNG HẢI LONG",
  student-id: "22207056",
  report-type: "BẢN MÔ TẢ ĐỒ ÁN LẤY ĐIỂM CỘNG",
  title-vi: "Nhận dạng điều chế số tự động trong kênh vô tuyến nhiễu bằng xử lý tín hiệu số và học sâu",
  title-en: "Automatic Digital Modulation Classification in Noisy Radio Channels Using Digital Signal Processing and Deep Learning",
  short-title: "DEEPDSP-AMC",
  video-url: "https://youtu.be/yl5Sk6plWXg",
  city: "Thành phố Hồ Chí Minh",
  date: "Tháng 08 năm 2026",
)

#let ink = rgb("#14202B")
#let navy = rgb("#123B63")
#let blue = rgb("#1769AA")
#let cyan = rgb("#0E8A9C")
#let pale-blue = rgb("#EEF5FA")
#let pale-cyan = rgb("#EAF7F8")
#let pale-gold = rgb("#FFF7E3")
#let gray-1 = luma(98%)
#let gray-2 = luma(94%)
#let gray-3 = luma(84%)
#let gray-4 = luma(48%)
#let rule = 0.55pt + ink
#let page-footer = context align(right)[#counter(page).display()]

#let noindent(body) = [
  #set par(first-line-indent: 0pt)
  #body
]

#let title-rule(width: 6cm, thickness: 0.75pt) = align(center)[
  #rect(width: width, height: thickness, fill: navy)
]

#let unnumbered-chapter(title) = [
  #pagebreak(weak: true)
  #{
    show heading: none
    heading(numbering: none)[#title]
  }
  #align(center)[#text(16pt, weight: "bold", fill: navy)[#title]]
  #v(0.10cm)
  #title-rule()
  #v(0.22cm)
]

#let inline-code(body) = box(
  fill: gray-2,
  stroke: 0.35pt + gray-3,
  inset: (x: 3pt, y: 1pt),
  outset: (y: 2pt),
  radius: 1.5pt,
)[#text(font: ("Cascadia Mono", "Consolas"), size: 0.88em)[#body]]

#let rawbox(body, title: none) = block(
  width: 100%,
  inset: (x: 9pt, y: 8pt),
  fill: gray-1,
  stroke: rule,
  radius: 2pt,
  breakable: true,
)[
  #set par(first-line-indent: 0pt, justify: false, leading: 0.40em)
  #if title != none [
    #text(weight: "bold", size: 9pt, fill: navy)[#title]
    #v(4pt)
  ]
  #text(font: ("Cascadia Mono", "Consolas"), size: 8.2pt)[#body]
]

#let pkw(body) = text(weight: "bold", fill: navy)[#body]
#let pcomment(body) = text(style: "italic", fill: gray-4)[#body]
#let pstep(indent, body) = (indent: indent, body: body)

#let pseudocode(caption, input, output, steps) = {
  let rows = ()
  for (index, step) in steps.enumerate() {
    rows.push(
      grid.cell(align: right + top)[
        #text(font: ("Cascadia Mono", "Consolas"), size: 7.8pt, fill: gray-4)[#(
          index + 1
        )]
      ],
    )
    rows.push(
      grid.cell(align: left + top)[
        #h(step.indent * 1.05em)
        #step.body
      ],
    )
  }

  figure(
    block(
      width: 100%,
      inset: (x: 9pt, y: 10pt),
      stroke: 0.65pt + navy,
      fill: gray-1,
      radius: 2pt,
    )[
      #set par(first-line-indent: 0pt, justify: false, leading: 0.58em)
      #set text(size: 9.1pt)
      #grid(
        columns: (4.9em, 1fr),
        column-gutter: 5pt,
        row-gutter: 4.5pt,
        align: left + top,
        [#text(weight: "bold", fill: navy)[Đầu vào:]], input,
        [#text(weight: "bold", fill: navy)[Đầu ra:]], output,
      )
      #v(7pt)
      #line(length: 100%, stroke: 0.45pt + gray-3)
      #v(6pt)
      #grid(
        columns: (1.7em, 1fr),
        column-gutter: 7pt,
        row-gutter: 4.6pt,
        align: left + top,
        ..rows,
      )
    ],
    kind: "algorithm",
    supplement: [Thuật toán],
    numbering: "1",
    gap: 8pt,
    caption: caption,
  )
}

#let source-listing(body, caption) = figure(
  body,
  kind: "code",
  supplement: [Mã nguồn],
  numbering: "1",
  caption: caption,
)

#let callout(title, body, kind: "note") = {
  let fill-color = if kind == "result" { pale-cyan } else if kind == "warning" {
    pale-gold
  } else { pale-blue }
  let marker = if kind == "result" { [KẾT QUẢ] } else if kind == "warning" {
    [GIỚI HẠN]
  } else { [GHI CHÚ KỸ THUẬT] }
  block(
    width: 100%,
    inset: (x: 10pt, y: 8pt),
    fill: fill-color,
    stroke: 0.65pt + navy,
    radius: 2pt,
    breakable: true,
  )[
    #set par(first-line-indent: 0pt, justify: true)
    #text(size: 8.2pt, weight: "bold", fill: blue)[#marker]
    #h(7pt)
    #text(weight: "bold")[#title]
    #v(3pt)
    #body
  ]
}

#let metric(value, label, note: none, tone: "neutral") = {
  let fill-color = if tone == "best" { pale-cyan } else if tone == "baseline" {
    pale-blue
  } else { gray-1 }
  block(width: 100%, inset: 7pt, stroke: rule, fill: fill-color, radius: 2pt)[
    #set par(first-line-indent: 0pt, justify: false)
    #align(center)[
      #text(size: 15pt, weight: "bold", fill: navy)[#value]
      #v(2pt)
      #text(size: 8.4pt, weight: "bold")[#label]
      #if note != none [#v(2pt)#text(size: 7.5pt, fill: gray-4)[#note]]
    ]
  ]
}

#let cellhead(body) = [
  #set par(first-line-indent: 0pt, justify: false)
  #text(weight: "bold")[#body]
]

#let cell(body) = [
  #set par(first-line-indent: 0pt, justify: true)
  #body
]

#let standard-table(columns: (), ..children) = table(
  columns: columns,
  stroke: 0.5pt + ink,
  inset: (x: 5.2pt, y: 4.0pt),
  fill: (_, y) => if y == 0 { pale-blue },
  ..children,
)

#let compact-table(columns: (), ..children) = {
  set text(size: 9.8pt)
  table(
    columns: columns,
    stroke: 0.45pt + ink,
    inset: (x: 3.8pt, y: 2.8pt),
    fill: (_, y) => if y == 0 { pale-blue },
    ..children,
  )
}

#let tbl(body, caption) = figure(
  body,
  kind: table,
  supplement: [Bảng],
  caption: caption,
)

#let plate-image(path, height: auto) = align(center)[
  #image(path, width: 100%, height: height, fit: "contain")
]

#let photo(path, caption, height: auto) = figure(
  block(width: 100%, inset: 3pt, stroke: 0.45pt + gray-3, fill: white)[
    #plate-image(path, height: height)
  ],
  kind: image,
  supplement: [Hình],
  caption: caption,
)

#let stage-box(title, subtitle: none, fill: white) = block(
  width: 100%,
  inset: (x: 5pt, y: 7pt),
  stroke: 0.65pt + navy,
  fill: fill,
  radius: 2pt,
)[
  #set par(first-line-indent: 0pt, justify: false)
  #align(center)[
    #text(size: 8.8pt, weight: "bold", fill: navy)[#title]
    #if subtitle != none [#v(2pt)#text(size: 7.2pt)[#subtitle]]
  ]
]

#let dsp-ai-pipeline() = figure(
  block(width: 100%, inset: 8pt, stroke: 0.75pt + navy, fill: gray-1)[
    #grid(
      columns: (1fr, auto, 1fr, auto, 1fr, auto, 1fr),
      column-gutter: 3pt,
      align: center + horizon,
      stage-box([Nguồn I/Q], subtitle: [6 kiểu điều chế], fill: pale-blue),
      [→],
      stage-box([Kênh số], subtitle: [RRC + CFO + AWGN]),
      [→],
      stage-box(
        [Hai nhánh],
        subtitle: [18 DSP features / 4-channel tensor],
        fill: pale-blue,
      ),
      [→],
      stage-box([Phân loại], subtitle: [RF + CNN + fusion]),
    )
    #v(7pt)
    #grid(
      columns: (1fr, auto, 1fr, auto, 1fr),
      column-gutter: 5pt,
      align: center + horizon,
      stage-box([Đánh giá], subtitle: [Accuracy, macro-F1]),
      [→],
      stage-box([Phân tích SNR], subtitle: [-12 đến 18 dB], fill: pale-cyan),
      [→],
      stage-box([Demo], subtitle: [chòm sao + PSD + xác suất]),
    )
  ],
  kind: image,
  supplement: [Hình],
  caption: [Chuỗi xử lý và đánh giá của hệ thống DEEPDSP-AMC],
)

#let cnn-architecture() = figure(
  block(width: 100%, inset: 8pt, stroke: 0.75pt + navy)[
    #grid(
      columns: (1fr, auto, 1fr, auto, 1fr, auto, 1fr, auto, 1fr),
      column-gutter: 3pt,
      align: center + horizon,
      stage-box([4 × 256], subtitle: [I, Q, |x|, sin Δφ], fill: pale-blue),
      [→],
      stage-box([Conv block 1], subtitle: [32 kênh + pool]),
      [→],
      stage-box([Conv block 2], subtitle: [64 kênh + pool], fill: pale-blue),
      [→],
      stage-box([Conv 96], subtitle: [global average]),
      [→],
      stage-box([Softmax], subtitle: [6 xác suất], fill: pale-cyan),
    )
  ],
  kind: image,
  supplement: [Hình],
  caption: [Kiến trúc CompactIQCNN dùng trong thí nghiệm; tổng cộng 81.030 tham số học được],
)
