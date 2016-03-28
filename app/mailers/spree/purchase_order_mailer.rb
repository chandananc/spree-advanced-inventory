module Spree
  class PurchaseOrderMailer < BaseMailer
    def partially_received_notice(po)
      @po = po

      unless @po.dropship
        attention = ""

        @po.purchase_order_line_items.each do |l|
          if l.price.to_f == 0.0
            attention = "*** ATTENTION REQUIRED *** "
          end
        end

        mail(to: [(@po.user.email ? @po.user.email : from_address)],
             bcc: ["it@800ceoread.com", "mel@800ceoread.com"],
             from: from_address,
             subject: "[#{po.number}] #{attention}Purchase order partially received")
      end
    end

    def completed_notice(po)
      @po = po

      unless @po.dropship
        @completed_at = po.updated_at.strftime("%m/%d/%Y %l:%M %P")

        attention = ""

        @po.purchase_order_line_items.each do |l|
          if l.price.to_f == 0.0
            attention = "*** ATTENTION REQUIRED *** "
          end
        end

        mail(to: [(@po.user.email ? @po.user.email : from_address)],
             bcc: ["it@800ceoread.com", "mel@800ceoread.com"],
             from: from_address,
             subject: "[#{po.number}] #{attention}Purchase order received at #{@completed_at}")
      end
    end


    def email_supplier(purchase_order, resend = false)
      @purchase_order = @po = purchase_order

      if resend
        type = "Resend"

      else
        type = "New"
      end

      if not @po.submitted_at or (type == "Resend" and @po.resend_po == true)

        subject = @po.email_subject
        if subject.blank?
          subject = "[#{Spree::Config[:site_name]}] #{type} #{@po.po_type} ##{@po.number}"
        else
          subject += " - #{type}"
        end

        sleep 1
        ext = @po.hardcopy_extension
        file_path = "/web/800ceoread.com/shared/pdfs/#{@po.number}.#{ext}"
        if Rails.env == "development"
          file_path = File.join(Rails.root,"tmp", "pdfs", @po.number + ".#{ext}")
        end
        attachments["#{@po.number}.#{ext}"] = File.read(file_path)
        mail(:to => @po.supplier.email.split(";"),
             :from => from_address,
             :cc => @po.supplier_contact.email.split(";"),
             :bcc => [@po.user.email, "it@800ceoread.com"],
             :reply_to => @po.user.email,
             :subject => subject)

        if resend
          if purchase_order.submitted_at.present? and not purchase_order.completed_at.present?
            purchase_order.status = "Submitted"
          elsif purchase_order.completed_at.present?
            purchase_order.status = "Completed"
          end
          purchase_order.resend_po = false
        else
          purchase_order.status = "Submitted"
        end
        purchase_order.submitted_at = Time.now
        purchase_order.save validate: false
      end
    end
  end
end
