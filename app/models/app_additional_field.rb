class AppAdditionalField < ActiveRecord::Base
  #attr_accessible :app_id,  :table_name, :additional_column_name, :created_at

  def self.add_column(table_name, col_name, app_id)
    if  table_name == "Topic"
      data_records = Topic.where(:hiveapplication_id => app_id)
      self.add_data_attribute(data_records, col_name)
    elsif table_name== "Post"
      topics = Topic.where(:hiveapplication_id => app_id)
      topics.each do |t|
        data_records = t.posts
        self.add_data_attribute(data_records, col_name)
      end
    end
  end

  def self.edit_column(table_name, old_column_name, new_column_name, app_id)
    if  table_name == "Topic"
      data_records = Topic.where(:hiveapplication_id => app_id)
      self.edit_data_attribute(data_records, old_column_name, new_column_name)
    elsif table_name == "Post"
      topics = Topic.where(:hiveapplication_id => app_id)
      topics.each do |t|
        data_records = t.posts
        self.edit_data_attribute(data_records, old_column_name, new_column_name)
      end
    end
  end


  def self.delete_column(table_name, col_name, app_id)
    if table_name == "Topic"
      data_records = Topic.where(:hiveapplication_id => app_id)
      self.delete_data_attribute(data_records,col_name)
    elsif table_name == "Post"
      topics = Topic.where(:hiveapplication_id => app_id)
      topics.each do |t|
        data_records = t.posts
        self.delete_data_attribute(data_records,col_name)
      end
    end
  end

  def self.edit_data_attribute(data_records, old_column_name, new_column_name)
    data_records.each do |u|
      if u.data.present?
        if u.data.has_key?(old_column_name) == false
          data_hash = u.data
          data_hash[new_column_name] =nil
          u.data = data_hash
          u.data_will_change!
          u.save!
        else
          data_hash = u.data.except(old_column_name)
          data = u.data[old_column_name]
          data_hash[new_column_name] = data
          u.data = data_hash
          u.data_will_change!
          u.save!
        end
      end
    end
  end

  def self.delete_data_attribute(data_records, column_name)
    data_records.each do |u|
      if u.data.present?
        if u.data.has_key?(column_name) == true
          data_hash = u.data.except(column_name)
          u.data = data_hash
          u.data_will_change!
          u.save!
        end
      end
    end
  end

  def self.add_data_attribute(data_records, column_name)
    data_records.each do |u|
      if u.data.present?
        if u.data.has_key?(column_name) == false
          data_hash = u.data
          data_hash[column_name] =nil
          u.data = data_hash
          u.data_will_change!
          u.save!
        end
      else
        data_hash = {}
        data_hash[column_name] = nil
        u.data = data_hash
        u.save!
      end
    end
  end
end