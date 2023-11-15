require "google_drive"

# Creates a session. This will prompt the credential via command line for the
# first time and save it to config.json file for later usages.
# See this document to learn how to create config.json:
# https://github.com/gimite/google-drive-ruby/blob/master/doc/authorization.md
session = GoogleDrive::Session.from_config("config.json")

# Gets list of remote files.
# session.files.each do |file|
#   p file.title
# end

module SheetApp

  include Enumerable

  class T
    @ws
    @ws_hash_Table
    def initialize()
      session = GoogleDrive::Session.from_config("config.json")
      @ws = session.spreadsheet_by_key("1bKB1wzaTOWW9b8AKbduJvLqgiAYE31WWLwYiUcFNWZU").worksheets[0]
      @ws_hash_Table = Hash.new
      setupTwoDArray
        # Metaprogramming:
      add_column_access
      add_subtotal_and_avarage
      add_return_row
      add_map_select_reduce
    end

# Create 2-dimentional array
# Hash tabela
    def setupTwoDArray
      (1..@ws.num_rows).each do |row|
        (1..@ws.num_cols).each do |col|
          @ws_hash_Table[[row,col]] = @ws[row,col]
        end
      end
      @ws_hash_Table
    end
# 1. Biblioteka može da vrati dvodimenzioni niz sa vrednostima tabele
# Works
    def returnTwoDArray
      @ws_hash_Table
    end


# 2. Moguće je pristupati redu preko t.row(1), i pristup njegovim elementima po sintaksi niza.
# Works, counts the first row as zeroth
    def row(x)
      if x.is_a?(Integer)
        rows = @ws.rows()
        rows[x]
      else
        puts "row zahteva integer vrednost"
      end
    end
  

# 3. Mora biti implementiran Enumerable modul(each funkcija), gde se vraćaju sve ćelije unutar tabele, sa leva na desno.
# Works
    def each
      @ws_hash_Table.each_value do |value|
        yield value
      end
    end
# 4. (0.5 Poena) Biblioteka treba da vodi računa o merge-ovanim poljima
# Testirano, vec vodi
# 5. (1.0 Poena) [ ] sintaksa mora da bude obogaćena tako da je moguće pristupati određenim vrednostima.
# Works 
    def [](*args)
        if args.size == 1 && args[0].is_a?(String)
            return column_name_to_column(args[0])
        end
        if args.size == 2 && args[0].is_a?(String) && args[1].is_a?(Integer)
            return get_field_value(args[0],args[1])
        end
    end
    
    def translate_column_name(col_name)
        col_num = 0
        column_row = Array.new
        column_row = row(0)
        col_num = column_row.find_index(col_name) + 1
        col_num
    end

    def column_name_to_column(col_name)
        col_num = translate_column_name(col_name)
        selected_column = Array.new
          (1..@ws.num_rows).each do |row|
            selected_column[row-1] = @ws[row,col_num]
          end
        selected_column
    end

    def get_field_value(col_name,row_num)
        col_num = translate_column_name(col_name)
        @ws[col_num,row_num]
    end

    def []=(*args)
        if args.size == 3 && args[0].is_a?(String) && args[1].is_a?(Integer)
            return set_field_value(args[0],args[1],args[-1])
        end
    end

    def set_field_value(col_name,row_num,value)
        col_num = translate_column_name(col_name)
        @ws[col_num,row_num]= value
        @ws.save
        setupTwoDArray
        @ws[col_num,row_num]
    end

# 6. (5.0 Poena) Biblioteka omogućava direktni pristup kolonama, preko istoimenih metoda.

    def add_method(c, m, &b)
        c.class_eval {
            define_method(m, &b)
        }
    end
    
    # Works
    def add_column_access
        row(0).each do |column|
            add_method(T,column.to_sym){
                column_num = translate_column_name(column)
                selected_column = Array.new
                (1..@ws.num_rows).each do |row| 
                    selected_column[row-1] = @ws[row,column_num]
                end
                selected_column
            } 
        end  
    end
    
    def add_subtotal_and_avarage
        add_method(Array,:sum){
            sum = 0
            for a in 1..self.length do
                sum+= self[a-1].to_i
            end
            sum
        }
        add_method(Array,:avg){
            avg = 0
            for a in 1..self.length do
                avg+= self[a-1].to_i
            end
            avg/=self.length
        }
    end

    def add_return_row
        (2..@ws.num_rows).each do |row|
            prepared_row = Array.new
            (1..@ws.num_cols).each do |col|
                prepared_row << @ws[row,col]
            end
            (1..@ws.num_cols).each do |col|
                unless @ws[row,col] == "" 
                    name = @ws[row,col]
                    # p name
                    add_method(Array,(name.to_s).to_sym){
                        prepared_row
                    }
                end
            end
        end
    end

    def add_map_select_reduce
        add_method(Array,:map){
            column_name = self.to_s
            column_number = translate_column_name(column_name)
            column = column_name_to_column(column_name)
            column.map{}
            @ws.update_cells(column_number,@ws.num_rows,column)
        }
        add_method(Array,:select){
            column_name = self.to_s
            column_number = translate_column_name(column_name)
            column = column_name_to_column(column_name)
            column.select{}
            @ws.update_cells(column_number,@ws.num_rows,column)
        }
        add_method(Array,:reduce){
            column_name = self.to_s
            column_number = translate_column_name(column_name)
            column = column_name_to_column(column_name)
            column.reduce{}
            @ws.update_cells(column_number,@ws.num_rows,column)
        }
    end

# end za klasu
  end
# Zona za testiranje Funkcija
    t = T.new
    # p t.returnTwoDArray
    # p t.row(0)
    # t.each do |element|
    #     p element
    # end
    # p t["Druga Kolona",1]
    # p t["Druga Kolona",2]= 2
    # p t.prvaKolona
    # p t.list1
    # p t.testRuby
    # p t.list1.sum
    # p t.list1.avg
    # p t.index
    # p t.index.student
    # p t.list1.rubyTest
end

