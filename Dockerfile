FROM chrisortman/ruby-25-on-rails:1.0
LABEL maintainer="chris-ortman@uiowa.edu"

# throw errors if Gemfile has been modified since Gemfile.lock
RUN gem install bundler -v 2.0.2

RUN mkdir /app
WORKDIR /app
COPY Gemfile /app/Gemfile
COPY Gemfile.lock /app/Gemfile.lock
COPY package.json /app/package.json
COPY yarn.lock /app/yarn.lock

RUN bundle install --without test development deploy --deployment
RUN yarn install --production

COPY . /app
COPY config/epic.yml.example /app/config/epic.yml
COPY config/ldap.yml.example /app/config/ldap.yml
COPY config/database.yml.example /app/config/database.yml

#RUN gem install Ascii85 -v 1.0.3 && gem install afm -v 0.2.2 #webpacker
RUN SECRET_KEY_BASE='b5b57bb7d19a59231f09d44bf72d9456bd9b45ca6ceaf770d0ef2a5e7d2997feb6a4fbe2e885616900f1afab9bf8a90c0cf2844b33f481b811c1c644e2ce06bd' RAILS_ENV=production bundle exec rails assets:precompile

COPY config/database.yml.docker /app/config/database.yml
RUN mkdir -p /var/www/html
VOLUME ["/var/www/html", "/app/public/system"]

EXPOSE 3000

RUN chmod +x /app/script/entrypoint.sh
ENTRYPOINT ["/app/script/entrypoint.sh"]
ENV RAILS_ENV production
CMD ["server"]
