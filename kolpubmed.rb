# encoding: utf-8


require 'open-uri'
require 'open_uri_redirections'
require 'net/http'
require 'uri'
require 'json'
require "i18n"
#uri = URI.parse(URI.encode('http://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi?retmode=json&retmax=100000&db=pubmed&term=BIFAP[All Fields]'))
#content = JSON.parse(open(uri).read)
#puts content

def getPaper(pmid)
    last_label = ""
    result = {}
    result['titulo'] = ""
    uri = URI.parse(URI.encode('https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=pubmed&id='+pmid.to_s+'&retmode=text&rettype=medline'))
    content = open(uri, :allow_redirections => :safe).read
    elements = content.split("\n")
    elements.each do |element|
        fields = element.split("-")
        if(fields.length>1)
            field_name = fields[0].strip
            last_label = field_name
            field_value = fields[1].strip
            if(field_name=="TI")
                result['titulo_ingles'] = field_value
                last_label = "TI"
            end
            if(field_name=="TT")
                result['titulo'] = field_value
                last_label = "TT"
            end
            if(field_name=="DP")
                result['fecha'] = field_value
                last_label = "DP"
            end
            if(field_name=="JT")
                result['revista'] = field_value
                last_label = "JT"
            end
        elsif (element != "")
            if (last_label=="TI")
                #puts "field_value="+element.strip

                result['titulo_ingles'] = result['titulo_ingles'] +" "+ element.strip
            end
            if (last_label=="TT")
                #puts "field_value="+element.strip

                result['titulo'] = result['titulo'] +" "+ element.strip
            end
        end
    end
    if (result['titulo'] == "")
        result['titulo'] = result['titulo_ingles']
    end
    return result
end

def Principal(colaboradores_file_name, output_file_name)
    #temp_http_proxy = ENV['http_proxy']
    #ENV['http_proxy'] = ENV['https_proxy']

    proxy_host = 'proxy.msc.es'
    proxy_port = 8080
    proxy_uri = URI.parse(ENV['https_proxy'])
    proxy_user, proxy_pass = proxy_uri.userinfo.split(/:/) if proxy_uri.userinfo



    outputfile = File.open(output_file_name, 'w')
    File.readlines(colaboradores_file_name).each do |line|

        line_utf8 = line.encode('UTF-8', :invalid => :replace)
        cols = line_utf8.split("\t")
        email = cols[2]
        nombre = cols[0]
        apellidos = cols[1]
        centro_salud = cols[3]
        provincia = cols[4].strip
        unless(email == 'Email primario')
            sleep 0.33
            uri = URI.parse(URI.encode('https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi?retmode=json&retmax=100000&db=pubmed&term='+email+'[All Fields]'))

            content = JSON.parse(open(uri, :allow_redirections => :safe).read)
            if(content['esearchresult']['count'].to_i>0)
                content['esearchresult']['idlist'].each do |pmid|

                    paper_details = getPaper(pmid)
                    puts pmid
                    puts paper_details
                   newline = nombre+"|"+apellidos+"|"+centro_salud+"|"+provincia+"|"+email+"|"+content['esearchresult']['count']+"|"+pmid.to_s+"|"+paper_details['titulo']+"|"+paper_details['revista']+"|"+paper_details['fecha']+"\n"
                   puts newline
                   outputfile.write(newline)
                end
            else
                newline = nombre+"|"+apellidos+"|"+centro_salud+"|"+provincia+"|"+email+"|"+content['esearchresult']['count']+"|"
                puts newline
                #outputfile.write(newline)
            end
        end
    end



end

Principal('colaboradores_20170327.txt','output_2017.txt')
