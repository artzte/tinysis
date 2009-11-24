module ForeignKeys
  
  FK_ACTIONS = {
    :set_null => 'SET NULL',
    :cascade => 'CASCADE',
    :restrict => 'RESTRICT'
  }
  
  # Verifies the integrity of a foreign key relationship by first querying to determine if there are any
  # orphaned records, then performs one of the following actions depending upon the ON DELETE action specified
  # for the association:
  #
  # :cascade    : deletes the dependent records (the records that reference the missing record)
  # :set_null   : sets the dependent record's referencing field to NULL, retaining the dependent record but removing the association to the missing record
  # :restrict   : throws an argument exception, since the assumption is that there is no fix for a broken dependency
  #
  # Run this method before adding the foreign key constraint
  
  def verify_foreign_key_references(from_table, from_column, to_table, to_column, action, report_only = false)
    raise ArgumentError, "Unknown action #{action}" unless FK_ACTIONS[action]
    
    select_sql = "SELECT COUNT(*) AS count FROM #{from_table} LEFT JOIN #{to_table} t2 ON #{from_table}.#{from_column} = t2.#{to_column} WHERE #{from_table}.#{from_column} IS NOT NULL AND t2.#{to_column} IS NULL"
    count_orphaned = ActiveRecord::Base.connection.select_values(select_sql).first.to_i

    if count_orphaned > 0
      msg = "Found #{count_orphaned} orphaned records in #{from_table} for association #{from_table}.#{from_column} => #{to_table}.#{to_column}"
      case(action)
      when :set_null
        proceed = true
        cleanup_sql = %{
          UPDATE #{from_table}
          LEFT JOIN #{to_table} t2 ON #{from_table}.#{from_column} = t2.#{to_column} 
          SET #{from_table}.#{from_column} = NULL
          WHERE #{from_table}.#{from_column} IS NOT NULL AND t2.#{to_column} IS NULL
        }
        msg << "; setting source table reference to NULL."
      when :cascade
        proceed = true
        cleanup_sql = %{DELETE #{from_table} FROM #{from_table} LEFT JOIN #{to_table} t2 ON #{from_table}.#{from_column} = t2.#{to_column} WHERE #{from_table}.#{from_column} IS NOT NULL AND t2.#{to_column} IS NULL}
        msg << "; deleting source table records."
      when :restrict
       msg << "; no cleanup action for a restrict relationship."
      end
      
      puts msg
      
      return if report_only

      raise ArgumentError, "Cannot proceed with migration; there are #{count_orphaned} records that I don't know how to deal with; query select was:\n\n#{select_sql}" unless proceed

      execute cleanup_sql
    end
    
  end
  
  # Adds the foreign key constraint to the table identified by the from_
  def add_foreign_key(from_table, from_column, to_table, to_column, action, options = {})
    
    constraint_name = options[:name]||"fk_#{from_table}_#{from_column}"

    fk_sql = %{ALTER TABLE #{from_table} ADD CONSTRAINT #{constraint_name} FOREIGN KEY (#{from_column}) REFERENCES #{to_table}(#{to_column})}
    
    fk_sql << " ON DELETE #{FK_ACTIONS[action]}"

    execute fk_sql

  end
  
end


# cribbed from http://wiki.rubyonrails.org/rails/pages/Foreign+Key+Schema+Dumper+Plugin
module ActiveRecord
  class SchemaDumper
    private
      def header_with_foreign_keys(stream)
        header_without_foreign_keys(stream)
        stream.puts "  disable_foreign_key_checks"
        stream.puts
      end
      alias_method_chain :header, :foreign_keys
    
      def trailer_with_foreign_keys(stream)
        stream.puts "  enable_foreign_key_checks"
        stream.puts
        trailer_without_foreign_keys(stream)
      end
      alias_method_chain :trailer, :foreign_keys

      def tables_with_foreign_keys(stream)
        tables_without_foreign_keys(stream)
        @connection.tables.sort.each do |tbl|
          next if tbl == "schema_info"
          foreign_key_constraints(tbl, stream)
        end
      end
      alias_method_chain :tables, :foreign_keys
      
      def foreign_key_constraints(table, stream)
        keys = @connection.foreign_key_constraints(table)
        keys.sort_by{ |i| i.name }.each do |key|
          stream.print "  add_foreign_key_constraint #{table.inspect}, #{key.foreign_key.inspect}, #{key.reference_table.inspect}, #{key.reference_column.inspect}, :name => #{key.name.inspect}, :on_update => #{key.on_update.inspect}, :on_delete => #{key.on_delete.inspect}"
          stream.puts
        end
        stream.puts unless keys.empty?
      end
  end
  
  module ConnectionAdapters    
    class ForeignKeyConstraintDefinition < Struct.new(:name, :foreign_key, :reference_table, :reference_column, :on_update, :on_delete) #:nodoc:
    end
    
    class AbstractAdapter
      protected
        def symbolize_foreign_key_constraint_action(constraint_action)
          constraint_action.downcase.gsub(/\s/, '_').to_sym
        end
    end
    
    class MysqlAdapter < AbstractAdapter
      def foreign_key_constraints(table, name = nil)
        constraints = [] 
        execute("SHOW CREATE TABLE #{table}", name).each do |row|
          row[1].each do |create_line|
            if create_line.strip =~ /CONSTRAINT `([^`]+)` FOREIGN KEY \(`([^`]+)`\) REFERENCES `([^`]+)` \(`([^`]+)`\)([^,]*)/          
              constraint = ForeignKeyConstraintDefinition.new(Regexp.last_match(1), Regexp.last_match(2), Regexp.last_match(3), Regexp.last_match(4), nil, nil)
            
              constraint_params = {}
              
              unless Regexp.last_match(5).nil?
                Regexp.last_match(5).strip.split('ON ').each do |param|
                  constraint_params[Regexp.last_match(1).upcase] = Regexp.last_match(2).strip.upcase if param.strip =~ /([^ ]+) (.+)/
                end
              end
            
              constraint.on_update = symbolize_foreign_key_constraint_action(constraint_params['UPDATE']) if constraint_params.include? 'UPDATE'
              constraint.on_delete = symbolize_foreign_key_constraint_action(constraint_params['DELETE']) if constraint_params.include? 'DELETE'

              constraints << constraint
            end
          end
        end
    
        constraints
      end
      
      def remove_foreign_key_constraint(table_name, constraint_name)
        execute "ALTER TABLE #{table_name} DROP FOREIGN KEY #{constraint_name}"
      end      
      
      def disable_foreign_key_checks
        execute('SET FOREIGN_KEY_CHECKS = 0')
      end

      def enable_foreign_key_checks
        execute('SET FOREIGN_KEY_CHECKS = 1')
      end
    
    end
    
    class Column
      private
        alias old_extract_limit extract_limit
        def extract_limit(sql_type)
          return 255 if sql_type =~ /enum/i
          old_extract_limit(sql_type)
        end

        alias old_simplified_type simplified_type
        def simplified_type(field_type)
          return :string if field_type =~ /enum/i
          old_simplified_type(field_type)
        end
    end
    
    module SchemaStatements
      # Adds a new foreign key constraint to the table.
      #
      # The constrinat will be named after the table and the reference table and column
      # unless you pass +:name+ as an option.
      #
      # options: :name, :on_update, :on_delete   
      def foreign_key_constraint_statement(condition, fkc_sym)
        action = { :restrict => 'RESTRICT', :cascade => 'CASCADE', :set_null => 'SET NULL' }[fkc_sym]
        action ? ' ON ' << condition << ' ' << action : ''
      end
      
      def add_foreign_key_constraint(table_name, foreign_key, reference_table, reference_column, options = {})
        constraint_name = options[:name] || "#{table_name}_ibfk_#{foreign_key}"
        
        sql = "ALTER TABLE #{table_name} ADD CONSTRAINT #{constraint_name} FOREIGN KEY (#{foreign_key}) REFERENCES #{reference_table} (#{reference_column})"
    
        sql << foreign_key_constraint_statement('UPDATE', options[:on_update])
        sql << foreign_key_constraint_statement('DELETE', options[:on_delete])
        
        execute sql
      end
      
      # options: Must enter one of the two options:
      #  1)  :name => the name of the foreign key constraint
      #  2)  :foreign_key => the name of the column for which the foreign key was created
      #      (only if the default constraint_name was used)
      def remove_foreign_key_constraint(table_name, options={})
        constraint_name = options[:name] || ("#{table_name}_ibfk_#{options[:foreign_key]}" if options[:foreign_key])
        raise ArgumentError, "You must specify the constraint name" if constraint_name.blank?
        
        @connection.remove_foreign_key_constraint(table_name, constraint_name)
      end
      
      def disable_foreign_key_checks
        @connection.disable_foreign_key_checks
      end
      
      def enable_foreign_key_checks
        @connection.enable_foreign_key_checks
      end
    end
  end
end
