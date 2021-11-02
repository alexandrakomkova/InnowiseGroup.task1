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
  get_info_about_product(html)[2].each_with_index do |weight, index|
    work_with_parsed_data(get_info_about_product(html)[0],
                          get_info_about_product(html)[1],
                          weight.text.to_s,
                          get_info_about_product(html)[3][index].text.to_s)
  end
end

def get_info_about_product(html)
  product_name = html.xpath('//h1[@class = "product_main_name"]').text
  product_img = html.xpath('//img[@id = "bigpic"]/@src')
  product_weight_variation = html.xpath('//span[@class = "radio_label"]')
  price_per_weight = html.xpath('//span[@class = "price_comb"]')
  [product_name, product_img, product_weight_variation, price_per_weight]
end

def work_with_parsed_data(name, img, weight, price)
  show_parsed_data(name, img, weight, price)
  write_to_file("parsingProducts.csv",
                prepare_data_to_write(name, img, weight, price),
                name)
end

def parse_one_page(count_products, url)
  product_page = get_html(url).xpath('//div[@class = "product-desc display_sd"]//@href')
  (0...count_products).each do |product_counter|
    parse_product(product_page[product_counter].to_s.gsub(/\s+/, ""))
  end
end

def set_count_products_to_parse(count_products, p_counter, product_per_page, url)
  url = form_page_url(url, p_counter) if p_counter > 1
  if count_products < product_per_page
    parse_one_page(count_products, url)
  else
    parse_one_page(product_per_page, url)
  end
end

def parse(url, file_name)
  create_file(file_name)
  count_products = get_html(url).xpath('//input[@id = "nb_item_bottom"]/@value').text.to_i
  product_per_page = 25
  count_pages = (count_products/product_per_page.to_f).ceil
  (1..count_pages).each do |p_counter|
    set_count_products_to_parse(count_products, p_counter, product_per_page, url)
    count_products -= product_per_page
  end
end

def form_page_url(url, p_counter)
  url + "?p=" + "#{p_counter}"
end

def create_file(file_name)
  CSV.open(file_name, 'w')
  set_headers_to_file(file_name)
end

def set_headers_to_file(file_name)
  headers = %w[name price image]
  CSV.open(file_name, 'a+') do |row|
    row << headers
  end
end

def show_parsed_data(name, img, weight, price)
  puts name.strip, img,  weight, price
end

def form_product_name(name,  weight)
  name.strip + "\n"+  weight
end

def form_product_price(price)
  price.gsub(/\s+/, "").chop
end

def form_product_weight(weight)
  case get_weight_measurement(weight.gsub(/\s+/, ""))
  when "Gr", "Gr."
    return get_weight_number(weight)+" gr"
  when "Kg", "Kg."
    return get_weight_number(weight)+" kg"
  else
    return weight
  end
end

def get_weight_measurement(weight)
  return weight.delete('0-9')
end

def get_weight_number(weight)
  return weight.delete('^0-9')
end

def prepare_data_to_write(name, img, weight, price)
  [form_product_name(name, form_product_weight(weight)), form_product_price(price), img]
end

def write_to_file(file_name, data_to_write, product_name)
  CSV.open(file_name, 'a+') do |row|
    row << data_to_write
  end
  puts "-----product #{product_name.strip} is written-----\n\n"
end

parse('https://www.petsonic.com/farmacia-para-gatos/', "parsingProducts.csv")


