class Progress
  def initialize(donors, goal, raised, start = 0)
    @donors = donors.gsub(/\D/,'').to_i - start.to_i
    @goal = [goal.gsub(/\D/,'').to_i,1].max
    @raised = raised.to_s
    @progress = [@donors.to_f / @goal, 1].min.round(2)
    @percent = (@progress * 100).round.to_s + '%'
    @percentfull = (@donors.to_f / @goal * 100).round.to_s + '%'
    @maxwidth = (730 * @progress + (@progress - 0.5) * 365).floor
  end
  def number_with_delimiter(number, delimiter=',')
    number.to_s.gsub(/(\d)(?=(\d\d\d)+(?!\d))/, "\\1#{delimiter}")
  end

  def flag_position
    if @progress < 0.95
      <<-CSS
        -webkit-transform: translateX(50%); 
        -ms-transform: translateX(50%); 
        transform: translateX(50%); 
        margin-left: -21px;'
      CSS
    else
      'margin-right:' + ((@progress - 1) * 100).round.to_s + '%'
    end
  end

  def progress_direction
    if @progress < 0.73
      <<-CSS
        color: #ffffff; 
        right: 0;
      CSS
    else
      <<-CSS
        color: #333333; 
        left: 0;
      CSS
    end
  end

  def progress_media_query(namespace)
    if @progress >= 0.5
      <<-CSS
          @media (max-width: #{@maxwidth}px) {
            #{namespace} .progress-count {
              color: #333333; 
              left: 0;
            }
          }
      CSS
    end
  end

  def barcss(namespace)

    <<-CSS
      /* Progress Bar: #{namespace} */
      #{namespace} .progress,
      #{namespace} .progress-percent {
        width: #{@percent};
      }
      #{namespace} .progress-percent:before {
        content: '#{@percentfull}';
        #{self.flag_position}
      }
      #{namespace} .progress-count {
        #{self.progress_direction}
      }
      
      #{namespace} .progress-count:after {
          content: "#{self.number_with_delimiter(@donors)} of #{number_with_delimiter(@goal)} donors";
      }
      #{namespace} .progress,
      #{namespace} .progress-percent {
          -webkit-animation: slideright #{[@progress, 0.3].max}s ease-out;
          animation: slideright #{[@progress, 0.3].max}s ease-out;
      }
      #{self.progress_media_query(namespace)}
    CSS
  end

  def statscss(namespace)
    <<-CSS
      /* Progress Stats: #{namespace} */
      #{namespace} .total-goal:before { content: "#{@percent}"; }
      #{namespace} .total-donors:before { content: "#{self.number_with_delimiter(@donors)}"; }
      #{namespace} .total-dollars:before { content: "#{@raised}"; }
    CSS
  end
end