require "prawn"
require "prawn/table"

class ResumesController < ApplicationController
  def new
  end

  def create
    pdf = generate_pdf(params)
    send_data(pdf, filename: "japanese_resume.pdf", type: "application/pdf", disposition: "attachment")
  end

  private

  def generate_pdf(data)
    regular_font = Rails.root.join("app", "assets", "fonts", "NotoSansJP-Regular.ttf")
    bold_font = Rails.root.join("app", "assets", "fonts", "NotoSansJP-Bold.ttf")

    Prawn::Document
      .new(page_size: "A4") do |pdf|
        pdf.font_families.update(
          "NotoSansJP" => {normal: regular_font, bold: bold_font}
        )

        pdf.font("NotoSansJP", style: :bold)
        pdf.text("履 歴 書", size: 20, align: :center)
        pdf.text(Time.now.strftime("%Y年 %m月 %d日"), align: :right)

        pdf.move_down(20)

        # Resume Info Table
        pdf.font("NotoSansJP", style: :normal)
        pdf.table(
          [
            ["ふりがな", "すずき はなこ"],
            ["名前", data[:name]],
            ["生年月日", "2000年 05月 10日生（満22歳）"],
            ["性別", "女性"]
          ],
          column_widths: [100, 300]
        )

        pdf.move_down(10)

        # Address & Contact Info
        pdf.table(
          [
            ["ふりがな", "とうきょうちよだく ひとつばし"],
            ["現住所", data[:address]],
            ["電話", data[:phone]],
            ["メールアドレス", data[:email]]
          ],
          column_widths: [100, 300]
        )

        pdf.move_down(10)

        # Education & Work Experience
        pdf.font("NotoSansJP", style: :bold)
        pdf.text("学歴", size: 14)
        pdf.move_down(5)
        pdf.font("NotoSansJP", style: :normal)
        pdf.text(data[:education])

        pdf.move_down(10)
        pdf.font("NotoSansJP", style: :bold)
        pdf.text("職歴", size: 14)
        pdf.move_down(5)
        pdf.font("NotoSansJP", style: :normal)
        pdf.text(data[:work_experience])

        pdf.move_down(10)
        pdf.font("NotoSansJP", style: :bold)
        pdf.text("自己PR", size: 14)
        pdf.move_down(5)
        pdf.font("NotoSansJP", style: :normal)
        pdf.text(data[:self_introduction])
      end
      .render
  end
end
