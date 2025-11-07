FROM ruby:3.1

# Install dependencies
RUN apt-get update && apt-get install -y build-essential

# Set working directory
WORKDIR /site

# Install Jekyll and Bundler
RUN gem install bundler jekyll

# Copy site files
COPY . /site

# Install gems
RUN bundle install

# Expose port
EXPOSE 4000

# Serve the site
CMD ["bundle", "exec", "jekyll", "serve", "--host=0.0.0.0"]
