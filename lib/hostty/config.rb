# frozen_string_literal: true

module Hostty
  class Config
    FILE_NAME = ".hostty.yml"
    BASE_PORT = 5000

    attr_reader :processes, :notices

    def initialize(processes:, notices:)
      @processes = processes
      @notices = notices
    end
  end
end
