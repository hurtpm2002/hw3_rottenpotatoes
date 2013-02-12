# Add a declarative step here for populating the DB with movies.

Given /the following movies exist/ do |movies_table|
  movies_table.hashes.each do |movie|
    begin
      # each returned element will be a hash whose key is the table header.
      # you should arrange to add that movie to the database here.
      ActiveRecord::Base.class_eval do
        Movie.create!(:title => movie[:title], :rating => movie[:rating], :release_date => movie[:release_date]) if
         (Movie.where(:title => movie[:title], :rating => movie[:rating], :release_date => movie[:release_date]).count == 0)
      end
    rescue
      flunk "Failed to add required move #{movie[:title]}"
    end
  end
end

Then /I should see all the ratings checked/ do
  ratings = []
  begin
    # each returned element will be a hash whose key is the table header.
    # you should arrange to add that movie to the database here.
    ActiveRecord::Base.class_eval do
      ratings = Movie.all(:select => 'rating', :group => 'rating', :order => 'rating').map(&:rating)
    end
  rescue
    flunk "Failed to retrieve set of all ratings"
  end
  ratings.each do |rating|
    step %{the "ratings_#{rating}" checkbox should be checked}
  end
end

# Make sure that one string (regexp) occurs before or after another one
#   on the same page

Then /I should see "(.*)" before "(.*)"/ do |e1, e2|
  #  ensure that that e1 occurs before e2.
  #  page.body is the entire content of the page as a string.
  assert page.body.index(e1) <= page.body.index(e2)
end

# Make it easier to express checking or unchecking several boxes at once
#  "When I uncheck the following ratings: PG, G, R"
#  "When I check the following ratings: G"

When /I (un)?check the following ratings: (.*)/ do |uncheck, rating_list|
  # HINT: use String#split to split up the rating_list, then
  #   iterate over the ratings and reuse the "When I check..." or
  #   "When I uncheck..." steps in lines 89-95 of web_steps.rb
  rating_list.split(%r{,\s*}).each do |rating|
    step %{I #{uncheck}check "ratings_#{rating}"}
  end
end

Then /I should (not )?see all movies with ratings([^:]*): (.*)/ do |negate, grammer_slug, rating_list|
  ratings = rating_list.split(%r{,\s*})
  movie_list = []
  begin
    ActiveRecord::Base.class_eval do
      if negate then
        ratings = Movie.all(:select => 'rating', :group => 'rating', :order => 'rating').map(&:rating) - ratings
      end
      movie_list = Movie.where(:rating => ratings)
    end
  rescue
    flunk "Failed to retrieve set of target titles"
  end
  movie_list.each do |movie|
    step %{I should #{negate}see "#{movie.title}"}
  end
end

Then /I should see all of the movies/ do
  titles = []
  begin
    # each returned element will be a hash whose key is the table header.
    # you should arrange to add that movie to the database here.
    ActiveRecord::Base.class_eval do
      titles = Movie.all(:select => 'title', :group => 'title', :order => 'title').map(&:title)
    end
  rescue
    flunk "Failed to retrieve set of all titles"
  end
  titles.each do |title|
    step %{I should see "#{title}"}
  end
end

Then /I should see the list of all movies sorted by (.*)/ do |sort_by|
  sort_by_column_name = sort_by.sub(/\s/,'_')
  movie_list = []
  ActiveRecord::Base.class_eval do
    ratings = Movie.all(:select => 'rating', :group => 'rating', :order => 'rating').map(&:rating)
    movie_list = Movie.where(:rating => ratings).order(%{#{sort_by_column_name} ASC})
  end
  last_movie = false
  movie_list.each do |movie|
    if last_movie then
      step %{I should see "#{last_movie.title}" before "#{movie.title}"}
    end
    last_movie = movie
  end
end
