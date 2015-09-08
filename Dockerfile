FROM ruby:2.2.2

ADD ./ /app
WORKDIR /app
RUN bundle install
ENTRYPOINT ["bundle", "exec", "ruby", "ga/ga.rb"]
CMD ["10", "10"]
