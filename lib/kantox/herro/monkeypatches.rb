module Kantox
  module Herro
    def self.console_to_html s
      s.gsub(/\e\[([\d;]+)m(.*?)\e\[([\d;]+)m/m) do |m|
        opening = self.parse $1.split ';'
        text = $2
        closing = self.parse $3.split ';'

        opening.map do |tag|
          attr = (tag.size > 1) && " style='#{tag.last}'" || ''
          "<#{tag.first}#{attr}>"
        end.join + text + opening.map { |tag| "</#{tag.first}>" }.reverse.join +
        closing.map do |tag|
          attr = (tag.size > 1) && " style='#{tag.last}'" || ''
          "<#{tag.first}#{attr}>"
        end.join
      end
    end

    class ::String
      def console_to_html
        Kantox::Herro.console_to_html self
      end
      def console_to_plain
        self.gsub(/\e\[.*?m/m, '')
      end
    end

  private
    def self.parse s
      s.inject({current: nil, tags: []}) do |memo, p|
        case memo[:current]
        when nil
          case p
          when '0', '00' then memo[:current] = nil
          when '01' then memo[:tags] << [:b]
          when '03' then memo[:tags] << [:i]
          when '04' then memo[:tags] << [:u]
          when '07' then memo[:tags] << [:s]
          when '38' then memo[:current] = ['color']
          when '48' then memo[:current] = ['background-color']
          else raise "Incorrect command in #{s}: [#{p}]."
          end
        when Array
          case p
          when '05' then memo[:current] = memo[:current].first
          else raise "Incorrect color in #{m}: [#{p}] after [38]."
          end
        when /color$/
          memo[:tags] << [:span, "#{memo[:current]}: #{con_2_rgb(p)};"]
          memo[:current] = nil
        else raise "Incorrect sequence in #{m}: [#{p}] after [#{memo[:current]}]."
        end
        memo
      end[:tags]
    end

    def self.con_2_rgb s
      case color = s.to_i
      when 0 then 'black'
      when 1 then '#800000'
      when 2 then '#008000'
      when 3 then 'brown'
      when 4 then 'navy'
      when 5 then '#800080'
      when 6 then '#008080'
      when 7 then '#C0C0C0'
      when 8 then '#808080'
      when 9 then '#FF0000'
      when 10 then '#00FF00'
      when 11 then '#FFFF00'
      when 12 then '#0000FF'
      when 13 then '#FF00FF'
      when 14 then '#00FFFF'
      when 15 then 'white'
      when 16...232
        r = (color - 16).to_s(6).rjust(3, '0').split('').map { |e| (e.to_i * 255 / 5).to_s(16).rjust(2, '0') }.join
        "\##{r}"
      when 232..255
        r = ((color - 232.0) * (255.0 / 24.0)).floor.to_s(16).rjust(2, '0')
        "\##{r}#{r}#{r}"
      end
    end
  end
end
