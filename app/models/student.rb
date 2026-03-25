class Student < ApplicationRecord

  belongs_to :school_program, optional: true
  belongs_to :study_level, optional: true

  has_one_attached :profile_image

  enum :gender, { other: 0, male: 1, female: 2 }, prefix: true

  CSV_HEADERS = {
    name_khmer: "គោត្តនាម-នាម",
    name_alphabet: "ឈ្មោះឡាតាំង",
    gender: "ភេទ",
    birthdate: "ថ្ងៃខែឆ្នាំកំណើត",
    academic_year_start: "academic_year_start",
    academic_year_end: "academic_year_end",
    started_at: "started_at",
    end_at: "end_at",
    started_at_khmer_calender: "started_at_khmer_calender",
    school_program: "ជំនាញ",
    study_level: "study_level"
  }
  GENDER_OTHER_KHMER = "ផ្សេងទៀត"
  GENDER_MALE_KHMER = "ប្រុស"
  GENDER_FEMALE_KHMER = "ស្រី"
  private_constant :CSV_HEADERS, :GENDER_OTHER_KHMER, :GENDER_MALE_KHMER, :GENDER_FEMALE_KHMER

  before_save   :set_student_number, :set_student_school_id

  validates :name_khmer,
    presence: true,
    length: { maximum: 100 }

  validates :name_alphabet,
    presence: true,
    length: { maximum: 100 },
    format: { with: /\A[a-zA-Z\s]+\z/ }

  validates :academic_year_start,
    presence: true,
    numericality: { only_integer: true, greater_than: 2000 }

  validates :academic_year_end,
    presence: true,
    numericality: { only_integer: true, greater_than: 2000 },
    comparison: { greater_than_or_equal_to: :academic_year_start }

  validates :started_at,
    presence: true,
    comparison: { greater_than: Date.new(2000, 1, 1) }

  validates :end_at,
    presence: true,
    comparison: { greater_than: :started_at }

  validates :started_at_khmer_calender,
    presence: true

  validates :school_program_id,
    presence: { message: "should be entered correctly." }

  validates :study_level_id,
    presence: { message: "should be entered correctly." }

  validates :birthdate,
    presence: { message: "should be entered correctly(Especially => កុម្ភៈ មីនា)." },
    comparison: { greater_than: Date.new(1900, 1, 1), allow_blank: true }

  validates :birth_place,
    inclusion: { in: PlacesInKhmer::Provinces::PROVINCES, allow_blank: true }

  validates :phone_number,
    length: { maximum: 20 },
    format: { with: /\A[0-9\-]+\z/, allow_blank: true }

  validates :parent_name,
    length: { maximum: 100 }

  validates :parent_phone_number,
    length: { maximum: 20 },
    format: { with: /\A[0-9\-]+\z/, allow_blank: true }

  validate :duplication, on: :create
  def duplication
    duplicated_student =
      Student.where(
        name_alphabet: name_alphabet,
        birthdate: birthdate,
        started_at: started_at,
        school_program_id: school_program_id
      )
    errors.add(:base, "Student is duplicated.") if duplicated_student.present?
  end
  private :duplication

  validate :prevent_update_unregistered_khmer_calendar, on: :update
  def prevent_update_unregistered_khmer_calendar
    return true unless self.will_save_change_to_attribute?(:started_at_khmer_calender)

    unless KhmerCalendar.khmer_calendar_text_exists?(self.attributes_in_database["started_at_khmer_calender"])
      errors.add(:base, "Before update, add #{self.attributes_in_database["started_at_khmer_calender"]} to Khmer Calendar.")
      return false
    else
      true
    end
  end

  class << self
    def default_started_at(year)
      Date.new(year, 12, 1)
    end

    def academic_year_list
      [*(Time.now.year - 2)..(Time.now.year + 5)]
    end

    def search_by_started_at(condition_year: , condition_month: nil)
      if condition_month
        condition_date = Date.new(condition_year, condition_month, 1)
        where("started_at >= ? AND started_at < ?", condition_date, condition_date + 1.month)
      else
        condition_date = Date.new(condition_year, 1, 1)
        where("started_at >= ? AND started_at < ?", condition_date, condition_date + 1.year)
      end
    end

    def search_by_ids(student_ids)
      return nil if student_ids.blank?

      where(id: student_ids).includes(:school_program).includes(:study_level)
    end

    def csv_output(students)
      CSV.generate do |csv|
        csv << CSV_HEADERS.values
        students.each do |student|
          csv_row = [
            student.name_khmer,
            student.name_alphabet,
            student.gender_khmer,
            ConvertKhmer::Date.khmer_date_simple(student.birthdate),
            ConvertKhmer::Date.khmer_number(student.academic_year_start),
            ConvertKhmer::Date.khmer_number(student.academic_year_end),
            ConvertKhmer::Date.khmer_date_simple(student.started_at),
            ConvertKhmer::Date.khmer_date_simple(student.end_at),
            student.started_at_khmer_calender,
            student.school_program.skill_khmer,
            student.study_level.name_khmer
          ]
          csv << csv_row
        end
      end
    end

    def import_csv(csv)
      csv_table = csv.read
      raise "File format is not correct." unless CSV_HEADERS.values.sort == csv_table.headers.sort

      students = []
      validation_errors = {}
      previous_identification_items = []
      csv_row_index = 0
      school_programs = SchoolProgram.all.index_by(&:skill_khmer)
      study_levels = StudyLevel.all.index_by(&:name_khmer)

      csv_table.each do |csv_row|
        student = Student.new
        student.set_bulk_insert_mode
        student.name_khmer = read_csv_row(csv_row, :name_khmer)
        break unless student.name_khmer

        student.name_alphabet = read_csv_row(csv_row, :name_alphabet)
        student.gender = gender_khmer_to_enum(read_csv_row(csv_row, :gender))
        student.academic_year_start =
          ConvertKhmer::Date.convert_khmer_number_to_number(read_csv_row(csv_row, :academic_year_start))
        student.academic_year_end =
          ConvertKhmer::Date.convert_khmer_number_to_number(read_csv_row(csv_row, :academic_year_end))
        student.started_at =
          ConvertKhmer::Date.convert_khmer_date_simple_to_date(read_csv_row(csv_row, :started_at))
        student.end_at =
          ConvertKhmer::Date.convert_khmer_date_simple_to_date(read_csv_row(csv_row, :end_at))
        student.started_at_khmer_calender = read_csv_row(csv_row, :started_at_khmer_calender)
        student.school_program_id = school_programs[read_csv_row(csv_row, :school_program)]&.id
        student.study_level_id = study_levels[read_csv_row(csv_row, :study_level)]&.id
        student.birthdate =
          ConvertKhmer::Date.convert_khmer_date_simple_to_date(read_csv_row(csv_row, :birthdate))
        csv_row_index += 1

        unless student.valid?
          joined_messages = ""
          student.errors.full_messages.each do |message|
            joined_messages += "- #{message}\n"
          end
          validation_errors[csv_row_index] = joined_messages
          next
        end
        current_identification_items =
          student.name_alphabet + student.birthdate.to_s + student.school_program_id.to_s
        if previous_identification_items.include?(current_identification_items)
          validation_errors[csv_row_index] = "Duplicated in this csv file."
          next
        end

        previous_identification_items << current_identification_items

        students << student
      end
      return false, validation_errors, 0 if validation_errors.present?

      transaction do
        students.each { |student| student.save! }
      end
      return true, nil, csv_row_index
    end

    def gender_khmer_to_enum(str)
      case str
      when GENDER_OTHER_KHMER
        genders[:other]
      when GENDER_MALE_KHMER
        genders[:male]
      when GENDER_FEMALE_KHMER
        genders[:female]
      end
    end

    def search_and_get_students_summary_for_bulk_delete(condition_academic_year_start:, condition_created_at:, condition_school_program_id:)
      students = search_students_for_bulk_delete(condition_academic_year_start, condition_created_at, condition_school_program_id)
      return if students.blank?

      summary = "#{students.length} number of students.\n"
      summary += "1: #{students.first.name_alphabet}\n"
      summary += "2: #{students.second.name_alphabet}\n" if students.length > 1
      if students.length > 2
        summary += "#{students.length.to_s}: #{students.last.name_alphabet}"
      end
      summary
    end

    def bulk_delete!(condition_academic_year_start:, condition_created_at:, condition_school_program_id:)
      students = search_students_for_bulk_delete(condition_academic_year_start, condition_created_at, condition_school_program_id)
      return if students.blank?

      transaction do
        students.each { |student| student.destroy! }
      end
    end

    private

    def read_csv_row(csv_row, item_sym)
      FileUtils::CsvFile.remove_zwnj_from_str(csv_row[CSV_HEADERS[item_sym]])
    end

    def search_students_for_bulk_delete(condition_academic_year_start, condition_created_at, condition_school_program_id)
      students = where(academic_year_start: condition_academic_year_start)
      students = students.where(created_at: condition_created_at.to_date.beginning_of_day..condition_created_at.to_date.end_of_day) unless condition_created_at.blank?
      students = students.where(school_program_id: condition_school_program_id) if condition_school_program_id.present?
      students
    end
  end

  def start_year
    return unless started_at

    started_at.year
  end

  def set_bulk_insert_mode
    @bulk_insert = true
  end

  def bulk_insert?
    @bulk_insert
  end

  def gender_khmer
    return GENDER_OTHER_KHMER if gender_other?

    return GENDER_MALE_KHMER if gender_male?

    GENDER_FEMALE_KHMER
  end

  private

  def set_student_number
    return if student_number.present?

    return unless academic_year_start

    max_student_number =
      Student.where("academic_year_start = ?", academic_year_start).
        maximum(:student_number) || 0

    self.student_number = max_student_number + 1
  end

  def set_student_school_id
    set_student_number

    return unless academic_year_start
    return if school_program.blank?
    return unless student_number

    self.student_school_id =
      academic_year_start.to_s + school_program.name + sprintf("%04d", student_number)
  end
end
