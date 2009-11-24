module Enumerable
  def grouped_hash
    assoc = {}

    each do |element|
     key = yield(element)

     if assoc.has_key?(key)
       assoc[key] << element
     else
       assoc[key] = [element]
     end
    end
    assoc
  end
end