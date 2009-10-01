class CsvWorker < Workling::Base

  def grabdata(csvparams)
     csvhash = {}
     heading = []
     @objname = csvparams['object_class']
     @def_attr_names = csvparams['def_attr_names']
     includes = csvparams['includes']
     joins = csvparams['joins']
     sort = csvparams['sort']
     conditions_string = csvparams['conditions_string']
     conditions_values = csvparams['conditions_values']
     if !joins then joins = {} end
     ## FIX ME - removing statuses from includes causes crash but need to investigate later ##
     if conditions_string && conditions_values
        allobjects = @objname.find(:all,
                               :include => includes,
                               :joins => joins.keys.join(' '),
                               :conditions => [ conditions_string, *conditions_values ],
                               :order => sort)
     else
        allobjects = @objname.find(:all,
                               :include => includes,
                               :joins => joins.keys.join(' '),
                               :order => sort)
     end

     # BEGIN EVAL EACH OBJ #
     allobjects.each do |myobj| 
        myhash = Hash.new
        # Process the non-associated (from local table only) data columns first - straightforward
        myobj.class.column_names.each do |a| 
           value = ''
           # Ensure all column names (name, cpus, etc)
           heading.push(a)
           value = myobj.send(a).to_s
           if myhash[a]
              myhash[a].push(value)
           else
              myhash[a] = [value]
           end
        end

        # Next, process the associated objects (joins from other tables)
        # Finds all associated models from the reflection key and loop through them (such as network_interfaces, group_names, etc)
        myobj.class.reflections.keys.each do |keyb|
           # For some reason rack model assoc causes 500 error -- need to look into later
           if keyb.to_s !~ /\brack\b/
              assoc = myobj.send(keyb)
              valid_assocobjs = []
              unless assoc.nil?
                 # Put all the objects into one dimensional array
                 if assoc.kind_of?(Array)
                     assoc.each do |b| 
                        valid_assocobjs.push(b)
                     end
                 else
                    valid_assocobjs.push(assoc)
                 end
              end
              valid_assocobjs.each do |a| 
                 # Loop through all objects, first look for their default search attr if they have one
                 sattr = ''
                 if a.class.respond_to?('default_search_attribute')
                    # Collect all associated model/method names (now that we've narrowed down legit fields)
                    heading.push(keyb.to_s)
                    sattr = a.class.default_search_attribute
                    # obtain value of the assoc model method by passing it the def search attr
                    if myhash[keyb.to_s] 
                       myhash[keyb.to_s].push(a.send(sattr))
                    else
                       myhash[keyb.to_s] = [ a.send(sattr) ]
                    end
                 end
              end
           end
        end

        csvhash[myobj.to_s] = myhash
     # END EVAL EACH OBJECT #
     end

     return csvhash
  end

  def sendata(options)
     csvparams = options[:csvparams]
     # build ALL data from models
     csvhash = self.grabdata(csvparams)
     csv = []
     # get form data for customized fields
     userfields = csvparams[:attributes]

     if userfields.nil?
       fields = @def_attr_names
     else
       fields = userfields
       if fields.grep('name').empty?
          fields.unshift('name')
       end
     end

     # Create heading line of fields 
     csv.push("#{fields.join(",")}\n\n")
     csvhash.keys.each do |csvnode|
        nodearr = []
        fields.each do |field|
           fieldarr = []
           fieldstr = ''
           if csvhash[csvnode][field]
              csvhash[csvnode][field].each do |value|
                 if !value.to_s.empty? 
                    fieldarr.push(value)
                 end
              end
           end
           if fieldarr.size > 1
              fieldstr = "#{fieldarr.join(",")}"
           else
              fieldstr = fieldarr.to_s
           end
           if fieldstr =~ /,/
              fieldstr = "\"#{fieldstr}\""
           end
           nodearr.push(fieldstr)
        end
        csv.push("#{nodearr.join(",")}\n")
     end

     # Send the data as csv file
     mailer_params = {}
     mailer_params[:object_class] = csvparams['object_class']
     Mailer.deliver_mail_csv("#{csvparams[:username]}@yellowpages.com", mailer_params, csv)
  end

end
