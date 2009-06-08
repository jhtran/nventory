class Mailer < ActionMailer::Base

  def notify_node_change(recipient, mailer_params)
    recipients  recipient
    from "nventory@#{@@domain_name}.com"
    subject "[nventory] Update to #{mailer_params[:changetype]} for node #{mailer_params[:nodename]}"
    body[:nodename] = mailer_params[:nodename]
    body[:changetype] = mailer_params[:changetype]
    body[:changevalue] = mailer_params[:changevalue]
    body[:oldvalue] = mailer_params[:oldvalue]
    body[:username] = mailer_params[:username]
    body[:time] = mailer_params[:time]
  end

  def notify_node_new(recipient, mailer_params)
    recipients  recipient
    from "nventory@#{@@domain_name}.com"
    subject "[nventory] New for node #{mailer_params[:nodename]}"
    body[:nodename] = mailer_params[:nodename]
    body[:changetype] = mailer_params[:changetype]
    body[:changevalue] = mailer_params[:changevalue]
    body[:username] = mailer_params[:username]
    body[:time] = mailer_params[:time]
  end

  def mail_csv(recipient, mailer_params, csv)
    recipients  recipient
    from "nventory@#{@@domain_name}.com"
    subject = "[nventory] #{mailer_params[:object_class].to_s.tableize} CSV Export"

    attachment :content_type => "text/csv", :filename => "#{mailer_params[:object_class].to_s.tableize}_export.csv", :body => csv.join
  end

end
