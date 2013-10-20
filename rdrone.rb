#!/usr/bin/env ruby
TEST = false
require 'Qt4'
require 'hornetseye_ffmpeg'
require 'hornetseye_qt4'
require 'argus'
eval `rbuic4 rdrone.ui`
include Hornetseye
class RDrone < Qt::Widget
  slots 'take_off()'
  slots 'land()'
  def initialize(parent = nil)
    super parent
    @ui = Ui::RDrone.new
    @ui.setupUi self
    if TEST
      @video = AVInput.new 'test.h264'
      @video_timer = startTimer 40
    else
      @video = AVInput.new 'tcp://192.168.1.1:5555'
      @nav = Argus::NavStreamer.new
      @video_timer = startTimer 0
      @nav_timer = startTimer 250
    end
  end
  def timerEvent(e)
    case e.timerId
    when @video_timer
      # @ui.xvwidget.write (@video.read_ubyte >= 64).conditional 255, 0
      begin
        @ui.xvwidget.write @video.read_ubyte
      rescue StandardError
      end
    when @nav_timer
      @nav.start
      @nav.receive_data.options.each do |opt|
        if opt.is_a? Argus::NavOptionDemo
          @ui.yawSpin.setValue opt.yaw
          @ui.pitchSpin.setValue opt.pitch
          @ui.rollSpin.setValue opt.roll
          @ui.batteryBar.setValue opt.battery_level
          @ui.stateLabel.setText opt.control_state_name.to_s
          p opt.altitude
          p opt.vx
          p opt.vy
          p opt.vz
        end
      end
    end
  end
  def closeEvent(e)
    killTimer @video_timer
    killTimer @nav_timer
  end
end
app = Qt::Application.new ARGV
window = RDrone.new
window.show
app.exec

