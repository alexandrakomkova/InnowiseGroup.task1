require 'csv'
require 'rubygems'
require 'curb'
require 'nokogiri'

def get_html(url)
  http = Curl.get(url) do |curl|
    curl.ssl_verify_peer=false
    curl.ssl_verify_host=0
  end
  Nokogiri::HTML(http.body_str)
end
def parse_product(product_url)
  html = get_html(product_url)
  product_name = html.xpath('//h1[@class = "product_main_name"]').text
  product_img = html.xpath('//img[@id = "bigpic"]/@src')
  product_weight_variation = html.xpath('//span[@class = "radio_label"]')
  price_per_weight = html.xpath('//span[@class = "price_comb"]')
  (0...product_weight_variation.length).each do |each_with_index|
    show_parsed_data(product_name,
              product_img,
              product_weight_variation[each_with_index].text.to_s,
              price_per_weight[each_with_index].text.to_s)
    write_to_file("parsingProducts.csv",
                  prepare_data_to_write(product_name,
                                        product_img,
                                        product_weight_variation[each_with_index].text.to_s,
                                        price_per_weight[each_with_index].text.to_s ),
                  product_name)
  end
end
def parse_one_page(count_products, url)
  product_page = get_html(url).xpath('//div[@class = "product-desc display_sd"]//@href')

  (0...count_products).each do |product_counter|
    parse_product(product_page[product_counter].to_s.gsub(/\s+/, ""))
  end
end
def parse(url, file_name)
  puts "-----start parsing-----\n\n"
  create_file(file_name)
  count_products = get_html(url).xpath('//input[@id = "nb_item_bottom"]/@value').text.to_i
  product_per_page = 25
  count_pages = (count_products/product_per_page.to_f).ceil
  (1..count_pages).each do |p_counter|
    url = url+"?p="+"#{p_counter}" if p_counter>1
    if(count_products<product_per_page)
      parse_one_page(count_products, url)
    else
      parse_one_page(product_per_page, url)
    end
    count_products-=product_per_page
  end
  puts "-----finished parsing-----"
end
def create_file(file_name)
  CSV.open(file_name, 'w')
  set_headers_to_file(file_name)
end
def set_headers_to_file(file_name)
  headers = %w[name img_src weight price]
  CSV.open(file_name, 'a+') do |row|
    row << headers
  end
end
def show_parsed_data(name, img, weight, price)
  puts name.strip, img,  weight, price
end
def prepare_data_to_write(name, img, weight, price)
  data_to_write = [name.strip, img,  weight, price]
end
def write_to_file(file_name, data_to_write, product_name)
  CSV.open(file_name, 'a+') do |row|
    row << data_to_write
  end
  puts "-----product #{product_name.strip} is written-----\n\n"
end
parse('https://www.petsonic.com/farmacia-para-gatos/', "parsingProducts.csv")






