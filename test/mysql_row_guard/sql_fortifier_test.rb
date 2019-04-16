require 'test_helper'
require 'mysql_row_guard'

class MysqlRowGuard::RowUserFake
  attr_accessor :current_org_id, :current_master_org_id
end

describe MysqlRowGuard::SqlFortifier do
  it 'returns sql without a view' do
    MysqlRowGuard.configure do |config|
      config.tables = %w[comments]
      config.sql_replacement = ''
    end
    sql_fortifier = MysqlRowGuard::SqlFortifier.for(sql: 'comments', configuration: MysqlRowGuard.configuration)
    assert_equal 'comments', sql_fortifier.to_s
  end

  it 'returns sql with a view' do
    user = MysqlRowGuard::RowUserFake.new
    user.current_master_org_id = 1
    MysqlRowGuard.configure do |config|
      config.tables = %w[comments]
      config.sql_replacement = 'my_%{table}_view'
      config.sql_variables = { my_var: 1 }
    end
    sql_fortifier = MysqlRowGuard::SqlFortifier.for(sql: 'comments', configuration: MysqlRowGuard.configuration)
    assert_equal '/* SET @my_var := 1 */ my_comments_view', sql_fortifier.to_s
  end

  it 'does not modify queries beginning with the SHOW command' do
    user = MysqlRowGuard::RowUserFake.new
    user.current_master_org_id = 1
    MysqlRowGuard.configure do |config|
      config.tables = %w[comments]
      config.sql_replacement = 'my_%{table}_view'
      config.sql_variables = { my_var: 1 }
    end
    sql_fortifier = MysqlRowGuard::SqlFortifier.for(sql: 'SHOW comments', configuration: MysqlRowGuard.configuration)
    assert_equal 'SHOW comments', sql_fortifier.to_s
  end

  it 'does not modify matching string literals' do
    user = MysqlRowGuard::RowUserFake.new
    user.current_master_org_id = 1
    MysqlRowGuard.configure do |config|
      config.tables = %w[posts comments]
      config.sql_replacement = 'my_%{table}_view'
      config.sql_variables = { my_var: 1 }
    end
    sql_fortifier = MysqlRowGuard::SqlFortifier.for(sql: 'SELECT * FROM posts WHERE type = "comments"', configuration: MysqlRowGuard.configuration)
    assert_equal '/* SET @my_var := 1 */ SELECT * FROM my_posts_view WHERE type = "comments"', sql_fortifier.to_s
  end

  it 'caches mysql' do
    user = MysqlRowGuard::RowUserFake.new
    user.current_master_org_id = 1
    MysqlRowGuard.configure do |config|
      config.tables = %w[comments]
      config.sql_replacement = 'my_%{table}_view'
      config.sql_variables = { my_var: 1 }
    end
    original_sql = 'SELECT * FROM something_else'
    cached_sql = MysqlRowGuard::SqlFortifier.for(sql: original_sql, configuration: MysqlRowGuard.configuration)
    already_cached_sql = nil
    MysqlRowGuard::SqlFortifier.stub :new, OpenStruct.new(sql: 'INVALID') do
      already_cached_sql = MysqlRowGuard::SqlFortifier.for(sql: cached_sql, configuration: MysqlRowGuard.configuration)
    end
    assert_equal cached_sql, already_cached_sql
  end


end
