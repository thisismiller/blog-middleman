# Copyright (c) 2005-2010 David Heinemeier Hansson
# 
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
# 
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

# This code is copied from rail's ActiveSupport.

module Inflector
    extend self

    # A singleton instance of this class is yielded by Inflector.inflections, which can then be used to specify additional
    # inflection rules. Examples:
    #
    #   Inflector.inflections do |inflect|
    #     inflect.plural /^(ox)$/i, '\1\2en'
    #     inflect.singular /^(ox)en/i, '\1'
    #
    #     inflect.irregular 'octopus', 'octopi'
    #
    #     inflect.uncountable "equipment"
    #   end
    #
    # New rules are added at the top. So in the example above, the irregular rule for octopus will now be the first of the
    # pluralization and singularization rules that is runs. This guarantees that your rules run before any of the rules that may
    # already have been loaded.
    class Inflections
        def self.instance
            @__instance__ ||= new
        end

        attr_reader :plurals, :singulars, :uncountables, :humans

        def initialize
            @plurals, @singulars, @uncountables, @humans = [], [], [], []
        end

        # Specifies a new pluralization rule and its replacement. The rule can either be a string or a regular expression.
        # The replacement should always be a string that may include references to the matched data from the rule.
        def plural(rule, replacement)
            @uncountables.delete(rule) if rule.is_a?(String)
            @uncountables.delete(replacement)
            @plurals.insert(0, [rule, replacement])
        end

        # Specifies a new singularization rule and its replacement. The rule can either be a string or a regular expression.
        # The replacement should always be a string that may include references to the matched data from the rule.
        def singular(rule, replacement)
            @uncountables.delete(rule) if rule.is_a?(String)
            @uncountables.delete(replacement)
            @singulars.insert(0, [rule, replacement])
        end

        # Specifies a new irregular that applies to both pluralization and singularization at the same time. This can only be used
        # for strings, not regular expressions. You simply pass the irregular in singular and plural form.
        #
        # Examples:
        #   irregular 'octopus', 'octopi'
        #   irregular 'person', 'people'
        def irregular(singular, plural)
            @uncountables.delete(singular)
            @uncountables.delete(plural)
            if singular[0,1].upcase == plural[0,1].upcase
                plural(Regexp.new("(#{singular[0,1]})#{singular[1..-1]}$", "i"), '\1' + plural[1..-1])
                plural(Regexp.new("(#{plural[0,1]})#{plural[1..-1]}$", "i"), '\1' + plural[1..-1])
                singular(Regexp.new("(#{plural[0,1]})#{plural[1..-1]}$", "i"), '\1' + singular[1..-1])
            else
                plural(Regexp.new("#{singular[0,1].upcase}(?i)#{singular[1..-1]}$"), plural[0,1].upcase + plural[1..-1])
                plural(Regexp.new("#{singular[0,1].downcase}(?i)#{singular[1..-1]}$"), plural[0,1].downcase + plural[1..-1])
                plural(Regexp.new("#{plural[0,1].upcase}(?i)#{plural[1..-1]}$"), plural[0,1].upcase + plural[1..-1])
                plural(Regexp.new("#{plural[0,1].downcase}(?i)#{plural[1..-1]}$"), plural[0,1].downcase + plural[1..-1])
                singular(Regexp.new("#{plural[0,1].upcase}(?i)#{plural[1..-1]}$"), singular[0,1].upcase + singular[1..-1])
                singular(Regexp.new("#{plural[0,1].downcase}(?i)#{plural[1..-1]}$"), singular[0,1].downcase + singular[1..-1])
            end
        end

        # Add uncountable words that shouldn't be attempted inflected.
        #
        # Examples:
        #   uncountable "money"
        #   uncountable "money", "information"
        #   uncountable %w( money information rice )
        def uncountable(*words)
            (@uncountables << words).flatten!
        end

        # Specifies a humanized form of a string by a regular expression rule or by a string mapping.
        # When using a regular expression based replacement, the normal humanize formatting is called after the replacement.
        # When a string is used, the human form should be specified as desired (example: 'The name', not 'the_name')
        #
        # Examples:
        #   human /_cnt$/i, '\1_count'
        #   human "legacy_col_person_name", "Name"
        def human(rule, replacement)
            @humans.insert(0, [rule, replacement])
        end

        # Clears the loaded inflections within a given scope (default is <tt>:all</tt>).
        # Give the scope as a symbol of the inflection type, the options are: <tt>:plurals</tt>,
        # <tt>:singulars</tt>, <tt>:uncountables</tt>, <tt>:humans</tt>.
        #
        # Examples:
        #   clear :all
        #   clear :plurals
        def clear(scope = :all)
            case scope
                when :all
                    @plurals, @singulars, @uncountables = [], [], []
                else
                    instance_variable_set "@#{scope}", []
            end
        end
    end

    # Yields a singleton instance of Inflector::Inflections so you can specify additional
    # inflector rules.
    #
    # Example:
    #   Inflector.inflections do |inflect|
    #     inflect.uncountable "rails"
    #   end
    def inflections
        if block_given?
            yield Inflections.instance
        else
            Inflections.instance
        end
    end

    # Returns the plural form of the word in the string.
    #
    # Examples:
    #   "post".pluralize             # => "posts"
    #   "octopus".pluralize          # => "octopi"
    #   "sheep".pluralize            # => "sheep"
    #   "words".pluralize            # => "words"
    #   "CamelOctopus".pluralize     # => "CamelOctopi"
    def pluralize(word)
        result = word.to_s.dup

        if word.empty? || inflections.uncountables.include?(result.downcase)
            result
        else
            inflections.plurals.each { |(rule, replacement)| break if result.gsub!(rule, replacement) }
            result
        end
    end

    # The reverse of +pluralize+, returns the singular form of a word in a string.
    #
    # Examples:
    #   "posts".singularize            # => "post"
    #   "octopi".singularize           # => "octopus"
    #   "sheep".singularize            # => "sheep"
    #   "word".singularize             # => "word"
    #   "CamelOctopi".singularize      # => "CamelOctopus"
    def singularize(word)
        result = word.to_s.dup

        if inflections.uncountables.any? { |inflection| result =~ /#{inflection}\Z/i }
            result
        else
            inflections.singulars.each { |(rule, replacement)| break if result.gsub!(rule, replacement) }
            result
        end
    end

    # Capitalizes the first word and turns underscores into spaces and strips a
    # trailing "_id", if any. Like +titleize+, this is meant for creating pretty output.
    #
    # Examples:
    #   "employee_salary" # => "Employee salary"
    #   "author_id"       # => "Author"
    def humanize(lower_case_and_underscored_word)
        result = lower_case_and_underscored_word.to_s.dup

        inflections.humans.each { |(rule, replacement)| break if result.gsub!(rule, replacement) }
        result.gsub(/_id$/, "").gsub(/_/, " ").capitalize
    end

    # Capitalizes all the words and replaces some characters in the string to create
    # a nicer looking title. +titleize+ is meant for creating pretty output. It is not
    # used in the Rails internals.
    #
    # +titleize+ is also aliased as as +titlecase+.
    #
    # Examples:
    #   "man from the boondocks".titleize # => "Man From The Boondocks"
    #   "x-men: the last stand".titleize  # => "X Men: The Last Stand"
    def titleize(word)
        humanize(underscore(word)).gsub(/\b('?[a-z])/) { $1.capitalize }
    end

    # Create the name of a table like Rails does for models to table names. This method
    # uses the +pluralize+ method on the last word in the string.
    #
    # Examples
    #   "RawScaledScorer".tableize # => "raw_scaled_scorers"
    #   "egg_and_ham".tableize     # => "egg_and_hams"
    #   "fancyCategory".tableize   # => "fancy_categories"
    def tableize(class_name)
        pluralize(underscore(class_name))
    end

    # Create a class name from a plural table name like Rails does for table names to models.
    # Note that this returns a string and not a Class. (To convert to an actual class
    # follow +classify+ with +constantize+.)
    #
    # Examples:
    #   "egg_and_hams".classify # => "EggAndHam"
    #   "posts".classify        # => "Post"
    #
    # Singular names are not handled correctly:
    #   "business".classify     # => "Busines"
    def classify(table_name)
        # strip out any leading schema name
        camelize(singularize(table_name.to_s.sub(/.*\./, '')))
    end

    # By default, +camelize+ converts strings to UpperCamelCase. If the argument to +camelize+
    # is set to <tt>:lower</tt> then +camelize+ produces lowerCamelCase.
    #
    # +camelize+ will also convert '/' to '::' which is useful for converting paths to namespaces.
    #
    # Examples:
    #   "active_record".camelize                # => "ActiveRecord"
    #   "active_record".camelize(:lower)        # => "activeRecord"
    #   "active_record/errors".camelize         # => "ActiveRecord::Errors"
    #   "active_record/errors".camelize(:lower) # => "activeRecord::Errors"
    def camelize(lower_case_and_underscored_word, first_letter_in_uppercase = true)
      if first_letter_in_uppercase
        lower_case_and_underscored_word.to_s.gsub(/\/(.?)/) { "::#{$1.upcase}" }.gsub(/(?:^|_)(.)/) { $1.upcase }
      else
        lower_case_and_underscored_word.to_s[0].chr.downcase + camelize(lower_case_and_underscored_word)[1..-1]
      end
    end

    # The reverse of +camelize+. Makes an underscored, lowercase form from the expression in the string.
    #
    # Changes '::' to '/' to convert namespaces to paths.
    #
    # Examples:
    #   "ActiveRecord".underscore         # => "active_record"
    #   "ActiveRecord::Errors".underscore # => active_record/errors
    def underscore(camel_cased_word)
      word = camel_cased_word.to_s.dup
      word.gsub!(/::/, '/')
      word.gsub!(/([A-Z]+)([A-Z][a-z])/,'\1_\2')
      word.gsub!(/([a-z\d])([A-Z])/,'\1_\2')
      word.tr!("-", "_")
      word.downcase!
      word
    end

    # Replaces underscores with dashes in the string.
    #
    # Example:
    #   "puni_puni" # => "puni-puni"
    def dasherize(underscored_word)
      underscored_word.gsub(/_/, '-')
    end

    # Removes the module part from the expression in the string.
    #
    # Examples:
    #   "ActiveRecord::CoreExtensions::String::Inflections".demodulize # => "Inflections"
    #   "Inflections".demodulize                                       # => "Inflections"
    def demodulize(class_name_in_module)
      class_name_in_module.to_s.gsub(/^.*::/, '')
    end

    # Creates a foreign key name from a class name.
    # +separate_class_name_and_id_with_underscore+ sets whether
    # the method should put '_' between the name and 'id'.
    #
    # Examples:
    #   "Message".foreign_key        # => "message_id"
    #   "Message".foreign_key(false) # => "messageid"
    #   "Admin::Post".foreign_key    # => "post_id"
    def foreign_key(class_name, separate_class_name_and_id_with_underscore = true)
      underscore(demodulize(class_name)) + (separate_class_name_and_id_with_underscore ? "_id" : "id")
    end

    # Tries to find a constant with the name specified in the argument string:
    #
    #   "Module".constantize     # => Module
    #   "Test::Unit".constantize # => Test::Unit
    #
    # The name is assumed to be the one of a top-level constant, no matter whether
    # it starts with "::" or not. No lexical context is taken into account:
    #
    #   C = 'outside'
    #   module M
    #     C = 'inside'
    #     C               # => 'inside'
    #     "C".constantize # => 'outside', same as ::C
    #   end
    #
    # NameError is raised when the name is not in CamelCase or the constant is
    # unknown.
    def constantize(camel_cased_word)
        names = camel_cased_word.split('::')
        names.shift if names.empty? || names.first.empty?

        constant = Object
        names.each do |name|
            constant = constant.const_defined?(name) ? constant.const_get(name) : constant.const_missing(name)
        end
        constant
    end

    # Turns a number into an ordinal string used to denote the position in an
    # ordered sequence such as 1st, 2nd, 3rd, 4th.
    #
    # Examples:
    #   ordinalize(1)     # => "1st"
    #   ordinalize(2)     # => "2nd"
    #   ordinalize(1002)  # => "1002nd"
    #   ordinalize(1003)  # => "1003rd"
    def ordinalize(number)
      if (11..13).include?(number.to_i % 100)
        "#{number}th"
      else
        case number.to_i % 10
          when 1; "#{number}st"
          when 2; "#{number}nd"
          when 3; "#{number}rd"
          else    "#{number}th"
        end
      end
    end
end


# String inflections define new methods on the String class to transform names for different purposes.
# For instance, you can figure out the name of a database from the name of a class.
#
#   "ScaleScore".tableize # => "scale_scores"
#
class String
  # Returns the plural form of the word in the string.
  #
  #   "post".pluralize             # => "posts"
  #   "octopus".pluralize          # => "octopi"
  #   "sheep".pluralize            # => "sheep"
  #   "words".pluralize            # => "words"
  #   "the blue mailman".pluralize # => "the blue mailmen"
  #   "CamelOctopus".pluralize     # => "CamelOctopi"
  def pluralize
    Inflector.pluralize(self)
  end

  # The reverse of +pluralize+, returns the singular form of a word in a string.
  #
  #   "posts".singularize            # => "post"
  #   "octopi".singularize           # => "octopus"
  #   "sheep".singularize            # => "sheep"
  #   "word".singularize             # => "word"
  #   "the blue mailmen".singularize # => "the blue mailman"
  #   "CamelOctopi".singularize      # => "CamelOctopus"
  def singularize
    Inflector.singularize(self)
  end

  # By default, +camelize+ converts strings to UpperCamelCase. If the argument to camelize
  # is set to <tt>:lower</tt> then camelize produces lowerCamelCase.
  #
  # +camelize+ will also convert '/' to '::' which is useful for converting paths to namespaces.
  #
  #   "active_record".camelize                # => "ActiveRecord"
  #   "active_record".camelize(:lower)        # => "activeRecord"
  #   "active_record/errors".camelize         # => "ActiveRecord::Errors"
  #   "active_record/errors".camelize(:lower) # => "activeRecord::Errors"
  def camelize(first_letter = :upper)
    case first_letter
      when :upper then Inflector.camelize(self, true)
      when :lower then Inflector.camelize(self, false)
    end
  end
  alias_method :camelcase, :camelize

  # Capitalizes all the words and replaces some characters in the string to create
  # a nicer looking title. +titleize+ is meant for creating pretty output. It is not
  # used in the Rails internals.
  #
  # +titleize+ is also aliased as +titlecase+.
  #
  #   "man from the boondocks".titleize # => "Man From The Boondocks"
  #   "x-men: the last stand".titleize  # => "X Men: The Last Stand"
  def titleize
    Inflector.titleize(self)
  end
  alias_method :titlecase, :titleize

  # The reverse of +camelize+. Makes an underscored, lowercase form from the expression in the string.
  # 
  # +underscore+ will also change '::' to '/' to convert namespaces to paths.
  #
  #   "ActiveRecord".underscore         # => "active_record"
  #   "ActiveRecord::Errors".underscore # => active_record/errors
  def underscore
    Inflector.underscore(self)
  end

  # Replaces underscores with dashes in the string.
  #
  #   "puni_puni" # => "puni-puni"
  def dasherize
    Inflector.dasherize(self)
  end

  # Removes the module part from the constant expression in the string.
  #
  #   "ActiveRecord::CoreExtensions::String::Inflections".demodulize # => "Inflections"
  #   "Inflections".demodulize                                       # => "Inflections"
  def demodulize
    Inflector.demodulize(self)
  end

  # Replaces special characters in a string so that it may be used as part of a 'pretty' URL.
  # 
  # ==== Examples
  #
  #   class Person
  #     def to_param
  #       "#{id}-#{name.parameterize}"
  #     end
  #   end
  # 
  #   @person = Person.find(1)
  #   # => #<Person id: 1, name: "Donald E. Knuth">
  # 
  #   <%= link_to(@person.name, person_path %>
  #   # => <a href="/person/1-donald-e-knuth">Donald E. Knuth</a>
  def parameterize(sep = '-')
    Inflector.parameterize(self, sep)
  end

  # Creates the name of a table like Rails does for models to table names. This method
  # uses the +pluralize+ method on the last word in the string.
  #
  #   "RawScaledScorer".tableize # => "raw_scaled_scorers"
  #   "egg_and_ham".tableize     # => "egg_and_hams"
  #   "fancyCategory".tableize   # => "fancy_categories"
  def tableize
    Inflector.tableize(self)
  end

  # Create a class name from a plural table name like Rails does for table names to models.
  # Note that this returns a string and not a class. (To convert to an actual class
  # follow +classify+ with +constantize+.)
  #
  #   "egg_and_hams".classify # => "EggAndHam"
  #   "posts".classify        # => "Post"
  #
  # Singular names are not handled correctly.
  #
  #   "business".classify # => "Busines"
  def classify
    Inflector.classify(self)
  end
  
  # Capitalizes the first word, turns underscores into spaces, and strips '_id'.
  # Like +titleize+, this is meant for creating pretty output.
  #
  #   "employee_salary" # => "Employee salary" 
  #   "author_id"       # => "Author"
  def humanize
    Inflector.humanize(self)
  end

  # Creates a foreign key name from a class name.
  # +separate_class_name_and_id_with_underscore+ sets whether
  # the method should put '_' between the name and 'id'.
  #
  # Examples
  #   "Message".foreign_key        # => "message_id"
  #   "Message".foreign_key(false) # => "messageid"
  #   "Admin::Post".foreign_key    # => "post_id"
  def foreign_key(separate_class_name_and_id_with_underscore = true)
    Inflector.foreign_key(self, separate_class_name_and_id_with_underscore)
  end

  # +constantize+ tries to find a declared constant with the name specified
  # in the string. It raises a NameError when the name is not in CamelCase
  # or is not initialized.
  #
  # Examples
  #   "Module".constantize # => Module
  #   "Class".constantize  # => Class
  def constantize
    Inflector.constantize(self)
  end
end
