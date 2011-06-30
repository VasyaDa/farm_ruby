class GameController < ApplicationController
  require 'builder'

  def index #Простой идентификатор сессии
    if !(session[:sid].is_a?(Bignum))
      session[:sid] =  Time.now.to_i;
    end
  end

  def init #Инициализация посаженных растений
    @game = Games.where("games.user = ?",session[:sid])
    xml = Builder::XmlMarkup.new(:indent => 2)
    xml.instruct!(:xml, :encoding => "UTF-8")
    xml.game(:fieldsX=>11, :fieldsY=>11, :fieldSize=>50) do
      @game.each do |field|
        xml.field(:id=>field.field_id, :plant=>field.plant, :growth=>field.growth)
      end
    end
    self.response_body = xml.target!
  end

  def plant #Посадка растения
    xml = Builder::XmlMarkup.new(:indent => 2)
    xml.instruct!(:xml, :encoding => "UTF-8")
    if request.get?
      @new_field = Games.new
      @new_field.field_id = request[:field_id]
      @new_field.plant = request[:plant]
      @new_field.growth = 1
      @new_field.user = session[:sid]
      if @new_field.save
        xml.field do
          xml.fieldId @new_field.field_id
          xml.plant @new_field.plant
          xml.growth @new_field.growth
        end
      else
        xml.field { xml.error 'Ошибка при записи значения новой ячейки в БД' }
      end
    else
      xml.field { xml.error 'Параметры неверны' }
    end
    self.response_body = xml.target!
  end

  def collect #Сбор растения
    xml = Builder::XmlMarkup.new(:indent => 2)
    xml.instruct!(:xml, :encoding => "UTF-8")
    if request.get?
      @collect_fields = Games.where("games.user = ? and field_id = ?",session[:sid],request[:field_id])
      if @collect_fields.count < 1
        xml.field { xml.error 'Здесь ничего не растет?' }
      end
      @collect_fields.each do |collect_field|
        if collect_field.growth < 5
          xml.field { xml.error 'А растение еще не выросло!!!' }
        else
          collect_field.destroy
          xml.field { xml.fieldId request[:field_id] }
        end
      end
    else
      xml.field { xml.error 'Параметры неверны' }
    end
    self.response_body = xml.target!
  end
  
  def growth #Вырастим все растения на единицу роста
    xml = Builder::XmlMarkup.new(:indent => 2)
    xml.instruct!(:xml, :encoding => "UTF-8")
    xml.game do
      @growth_fields = Games.where("games.user = ? and growth < 5",session[:sid])
      xml.error 'Ничего не выросло!!! Может расти нечему?' if @growth_fields.count < 1
      @growth_fields.each do |growth_field|
        growth_field.growth = growth_field.growth + 1
        growth_field.save
        xml.field do
          xml.fieldId growth_field.field_id
          xml.plant growth_field.plant
          xml.growth growth_field.growth
        end
      end
    end
    self.response_body = xml.target!
  end

  def swplant #меняем местами поля при перетаскивании
    xml = Builder::XmlMarkup.new(:indent => 2)
    xml.instruct!(:xml, :encoding => "UTF-8")

    if request.get?
      @source_field = Games.where("games.user = ? and field_id = ?",session[:sid],request[:source_id]).limit(1)
      if @source_field.count < 1
        xml.field { xml.error 'В ячейке нет растения для переноса' }
      else
        @source_field.each do |source_field|
          source_field.field_id = request[:dest_id]
          source_field.save(:validate => false)
          @dest_field = Games.where("games.user = ? and field_id = ?",session[:sid],request[:dest_id]).limit(1)
          if @dest_field.count > 1
            @dest_field.each do |dest_field|
              dest_field.field_id = request[:source_id]
              dest_field.save(:validate => false)
            end
          end
        end
        xml.fields do
          xml.sourceField request[:source_id]
          xml.destField request[:dest_id]
        end
      end
    else
      xml.field { xml.error 'Параметры неверны' }
    end
    self.response_body = xml.target!
  end
  
end