# app/controllers/resumes_controller.rb
require "prawn"
require "prawn/table"

class ResumesController < ApplicationController
  def home
  end

  def new
  end

  def create
    uploaded_photo = params[:photo]
    photo_path = nil

    if uploaded_photo
      photo_path = Rails.root.join("tmp", "uploaded_photo.jpg")
      File.open(photo_path, "wb") { |file| file.write(uploaded_photo.read) }
    end

    pdf = generate_pdf(params, photo_path)
    send_data(pdf, filename: "japanese_resume.pdf", type: "application/pdf", disposition: "attachment")

    File.delete(photo_path) if photo_path && File.exist?(photo_path)
  end

  private

  def generate_pdf(data, photo_path)
    regular_font = Rails.root.join("app", "assets", "fonts", "NotoSansJP-Regular.ttf")
    bold_font = Rails.root.join("app", "assets", "fonts", "NotoSansJP-Bold.ttf")

    Prawn::Document
      .new(page_size: "A4", margin: [50, 50, 40, 50]) do |pdf|
        pdf.font_families.update(
          "NotoSansJP" => {
            normal: regular_font.to_s,
            bold: bold_font.to_s
          }
        )
        pdf.font("NotoSansJP")

        # -- Title and Date at the top --
        pdf.font_size(18) do
          pdf.text("履 歴 書", align: :center, style: :bold)
        end

        # Place the date on the top-right
        # Slightly move up if needed
        pdf.move_cursor_to(pdf.cursor + 15)
        pdf.font_size(16) do
          pdf.text_box(
            data[:date].presence || Time.now.strftime("%Y年 %m月 %d日"),
            at: [pdf.bounds.right - 100, pdf.cursor],
            width: 100,
            height: 12,
            align: :right
          )
        end

      # -- Photo box in the top-right corner --
      photo_box_width = 100
      photo_box_height = 120

      if photo_path && File.exist?(photo_path)
        pdf.image photo_path, at: [pdf.bounds.right - photo_box_width, pdf.cursor - 20], width: 100, height: 120
      else
        pdf.bounding_box(
          [pdf.bounds.right - photo_box_width, pdf.cursor - 20],
          width: photo_box_width,
          height: photo_box_height
        ) do
          pdf.stroke_rectangle([0, photo_box_height], photo_box_width, photo_box_height)
          pdf.text_box("写真貼付", at: [0, photo_box_height - 15], width: photo_box_width, height: 15, align: :center, size: 10)
        end
      end

        # Move the main cursor below the photo area to avoid overlap
        # We'll move down enough space to clear the photo placeholder
        pdf.move_down(150)

        # -- Personal Information Section --

        # 1) Furigana row
        furigana_label_width = 60
        table_data = [
          [
            {content: "ふりがな", font_style: :bold, size: 10, align: :center, width: furigana_label_width},
            {content: data[:furigana].presence || "すずき はなこ", size: 12}
          ]
        ]
        pdf.table(table_data, width: pdf.bounds.width) do |t|
          t.cells.border_width = 0.5
          t.cells.padding = [5, 5, 5, 5]
          t.column(0).row(0).valign = :center
        end

        # 2) Name row
        name_label_width = 60
        table_data = [
          [
            {content: "氏 名", font_style: :bold, size: 10, align: :center, width: name_label_width},
            {content: data[:name].presence || "鈴木 花子", size: 14, font_style: :bold}
          ]
        ]
        pdf.table(table_data, width: pdf.bounds.width) do |t|
          t.cells.border_width = 0.5
          t.cells.padding = [5, 5, 5, 5]
        end

        # 3) Birthdate and gender row
        birth_label_width = 60
        birth_text = data[:birthdate].presence || "2000年 05月 10日生 (満#{data[:age] || "22"}歳)"
        gender_text = data[:gender].presence || "女性"
        table_data = [
          [
            {content: "生年月日", font_style: :bold, size: 10, align: :center, width: birth_label_width},
            {content: birth_text, size: 10},
            {content: gender_text, size: 10, width: 60, align: :center}
          ]
        ]
        pdf.table(table_data, width: pdf.bounds.width) do |t|
          t.cells.border_width = 0.5
          t.cells.padding = [5, 5, 5, 5]
        end

        pdf.move_down(5)

        # 4) Address furigana row
        table_data = [
          [
            {content: "ふりがな", font_style: :bold, size: 10, align: :center, width: furigana_label_width},
            {content: data[:address_furigana].presence || "とうきょうとちよだくひとつばし", size: 10}
          ]
        ]
        pdf.table(table_data, width: pdf.bounds.width) do |t|
          t.cells.border_width = 0.5
          t.cells.padding = [5, 5, 5, 5]
        end

        # 5) Address + phone + email
        postal_code = data[:postal_code].presence || "100-0003"
        address = data[:address].presence || "東京都千代田区一ツ橋1-1-1"
        phone = data[:phone].presence || "050-0000-0000"
        email = data[:email].presence || "hanako_suzuki_pr@gmail.com"

        # First row: "現住所" label, postal code, phone label, phone
        table_data = [
          [
            {content: "現住所", font_style: :bold, size: 10, align: :center, width: 60},
            {content: postal_code, size: 10, width: 100},
            {content: "電話", font_style: :bold, size: 10, align: :center, width: 40},
            {content: phone, size: 10}
          ]
        ]
        pdf.table(table_data, width: pdf.bounds.width) do |t|
          t.cells.border_width = 0.5
          t.cells.padding = [5, 5, 5, 5]
        end

        # Second row: address, "メールアドレス", email
        table_data = [
          [
            {content: address, size: 10, width: 160},
            {content: "メールアドレス", font_style: :bold, size: 10, align: :center, width: 80},
            {content: email, size: 10}
          ]
        ]
        pdf.table(table_data, width: pdf.bounds.width) do |t|
          t.cells.border_width = 0.5
          t.cells.padding = [5, 5, 5, 5]
        end

        pdf.move_down(5)

        # 6) Contact info (連絡先) - often the same as address or left blank
        # We'll just replicate the structure
        table_data = [
          [
            {content: "連絡先", font_style: :bold, size: 10, align: :center, width: 60},
            {content: "同上", size: 10, width: 100, align: :center},
            {content: "電話", font_style: :bold, size: 10, align: :center, width: 40},
            {content: "", size: 10}
          ]
        ]
        pdf.table(table_data, width: pdf.bounds.width) do |t|
          t.cells.border_width = 0.5
          t.cells.padding = [5, 5, 5, 5]
        end

        table_data = [
          [
            {content: "", size: 10, width: 160},
            {content: "メールアドレス", font_style: :bold, size: 10, align: :center, width: 80},
            {content: "", size: 10}
          ]
        ]
        pdf.table(table_data, width: pdf.bounds.width) do |t|
          t.cells.border_width = 0.5
          t.cells.padding = [5, 5, 5, 5]
        end

        # -- Education Section --
        pdf.move_down(20)
        pdf.font_size(12)
        pdf.text("学歴", style: :bold)

        pdf.move_down(5)
        education_table_data = [
          [
            {content: "年", width: 50, align: :center},
            {content: "月", width: 50, align: :center},
            {content: "学 歴", align: :center}
          ]
        ]

        if data[:education].present?
          data[:education].split("\n").each do |entry|
            if entry =~ /(\d{4})\s*[年]?\s*(\d{1,2})\s*[月]?\s*(.*)/
              year = $1
              month = $2
              desc = $3
              education_table_data << [
                {content: year, align: :center},
                {content: month, align: :center},
                {content: desc}
              ]
            end
          end
        else
          # Sample data
          education_table_data <<
            [
              {content: "2019", align: :center},
              {content: "03", align: :center},
              {content: "東京都立第一高等学校　卒業"}
            ]
          education_table_data <<
            [
              {content: "2019", align: :center},
              {content: "04", align: :center},
              {content: "第一大学　入学"}
            ]
          education_table_data <<
            [
              {content: "2023", align: :center},
              {content: "03", align: :center},
              {content: "第一大学　卒業見込み"}
            ]
        end

        pdf.table(education_table_data, width: pdf.bounds.width) do |t|
          t.cells.border_width = 0.5
          t.cells.padding = [5, 5, 5, 5]
        end

        # -- Work Experience Section --
        pdf.move_down(20)
        pdf.text("職歴", style: :bold)
        pdf.move_down(5)

        work_table_data = [
          [
            {content: "年", width: 50, align: :center},
            {content: "月", width: 50, align: :center},
            {content: "職 歴", align: :center}
          ]
        ]

        if data[:work_experience].present?
          data[:work_experience].split("\n").each do |entry|
            if entry =~ /(\d{4})\s*[年]?\s*(\d{1,2})\s*[月]?\s*(.*)/
              year = $1
              month = $2
              desc = $3
              work_table_data << [
                {content: year, align: :center},
                {content: month, align: :center},
                {content: desc}
              ]
            end
          end
        else
          # Sample data
          work_table_data <<
            [
              {content: "2019", align: :center},
              {content: "04", align: :center},
              {content: "個別指導東京塾　アルバイト入社"}
            ]
        end

        pdf.table(work_table_data, width: pdf.bounds.width) do |t|
          t.cells.border_width = 0.5
          t.cells.padding = [5, 5, 5, 5]
        end

        # -- Qualifications Section --
        pdf.move_down(20)
        pdf.text("免許・資格", style: :bold)
        pdf.move_down(5)

        qualifications_table_data = [
          [
            {content: "年", width: 50, align: :center},
            {content: "月", width: 50, align: :center},
            {content: "免許・資格", align: :center}
          ]
        ]

        if data[:qualifications].present?
          data[:qualifications].split("\n").each do |entry|
            if entry =~ /(\d{4})\s*[年]?\s*(\d{1,2})\s*[月]?\s*(.*)/
              year = $1
              month = $2
              desc = $3
              qualifications_table_data << [
                {content: year, align: :center},
                {content: month, align: :center},
                {content: desc}
              ]
            end
          end
        else
          # Sample data
          qualifications_table_data <<
            [
              {content: "2020", align: :center},
              {content: "05", align: :center},
              {content: "普通自動車第一種運転免許　取得"}
            ]
          qualifications_table_data <<
            [
              {content: "2022", align: :center},
              {content: "02", align: :center},
              {content: "秘書検定1級　取得"}
            ]
          qualifications_table_data <<
            [
              {content: "2022", align: :center},
              {content: "11", align: :center},
              {content: "TOEICスコア900点　取得"}
            ]
        end

        pdf.table(qualifications_table_data, width: pdf.bounds.width) do |t|
          t.cells.border_width = 0.5
          t.cells.padding = [5, 5, 5, 5]
        end

        # -- Self Introduction / Personal PR --
        pdf.move_down(20)
        pdf.text("志望の動機・自己PRなど", style: :bold)
        pdf.move_down(5)

        self_intro = if data[:self_introduction].present?
          data[:self_introduction]
        else
          "私が貴社を志望した理由は、学生時代の塾講師経験を活かしたいと考えたことと、\n「生徒一人一人に寄り添う塾」というコンセプトに共感を覚えたためです。..."
        end

        pdf.text_box(
          self_intro,
          at: [0, pdf.cursor],
          width: pdf.bounds.width,
          height: 100,
          overflow: :shrink_to_fit
        )
      end
      .render
  end
end
