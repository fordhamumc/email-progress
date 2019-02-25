class Leaderboard
  def initialize(query, leaderboards)
    @leaderboard = reduce(query, leaderboards)
  end

  def reduce(search, arr)
    arr.map do |lb|
      if lb.at_css('caption h3').content.strip.downcase == search
        lb.css('tbody tr').map do |item|
          {
              'name' => child(1, item),
              'donors' => child(2, item),
              'dollars' => child(3, item),
              'goal' => child(4, item),
              'percent' => child(5, item)
          }
        end
      end
    end.compact[0] || []
  end

  def child(num, arr)
    match = arr.at_css("td:nth-child(#{num})")
    match ? match.content.strip : ''
  end

  def sort(column, dir = 'desc')
    @leaderboard.sort! do |a,b|
      a,b = b,a if dir == 'desc'
      a[column].gsub(/\D/,'').to_i <=> b[column].gsub(/\D/,'').to_i
    end
    self
  end

  def strip(field, phrase)
    @leaderboard.each do |item|
      item[field].gsub!(phrase,'')
    end
    self
  end

  def css(namespace, num = 5)
    lb = if num > 0 then @leaderboard.take(num) else @leaderboard end

    lb.map.with_index do |item, i|
      result = ''
      item.each do |key, value|
        result << "
        #lb-#{namespace}-#{i + 1} .#{key}:before { content: \"#{value}\"; }"
      end
      result
    end.join("\n")
  end

  def to_json()
    @leaderboard.to_json
  end
end