module FileUtils
  class CsvFile
    BOM_CODE = "\xEF\xBB\xBF"
    ZERO_WITH_NON_JOINER_CODE = "\u200C"
    ZERO_WIDTH_SPACE = "\u200b"
    private_constant :BOM_CODE, :ZERO_WITH_NON_JOINER_CODE, :ZERO_WIDTH_SPACE

    class << self
      def set_bom(csv_string)
        BOM_CODE + csv_string
      end

      def remove_zwnj_from_str(str)
        return if str.nil?

        str.gsub(ZERO_WITH_NON_JOINER_CODE, "").gsub(ZERO_WIDTH_SPACE, "")
      end
    end
  end
end