require "prawn"

class ResumesController < ApplicationController
  def new
  end

  def create
    pdf = generate_pdf(params)
    send_data(pdf, filename: "japanese_resume.pdf", type: "application/pdf")
  end

  private

  def generate_pdf(data)
    Prawn::Document
      .new do |pdf|
        pdf.text("履歴書", size: 18, style: :bold, align: :center)
        pdf.move_down(10)
        pdf.text("名前: #{data[:name]}")
        pdf.text("メール: #{data[:email]}")
        pdf.text("電話番号: #{data[:phone]}")
        pdf.text("住所: #{data[:address]}")
        pdf.move_down(10)
        pdf.text("職務経歴:", style: :bold)
        pdf.text(data[:work_experience])
        pdf.move_down(10)
        pdf.text("学歴:", style: :bold)
        pdf.text(data[:education])
        pdf.move_down(10)
        pdf.text("自己PR:", style: :bold)
        pdf.text(data[:self_introduction])
      end
      .render
  end
end
