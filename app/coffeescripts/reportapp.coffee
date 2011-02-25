# This file is part of meego-test-reports
#
# Copyright (C) 2010 Nokia Corporation and/or its subsidiary(-ies).
#
# Authors: Sami Hangaslammi <sami.hangaslammi@leonidasoy.fi>
#          Jarno Keskikangas <jarno.keskikangas@leonidasoy.fi>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public License
# version 2.1 as published by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA
# 02110-1301 USA
#


#####################################################################
# Additional string methods
#####################################################################

String::capitalize = -> this.charAt(0).toUpperCase() + this.substr(1).toLowerCase()
String::titleCase  = -> this.replace /\w\S*/g, s -> s.capitalize()
String::htmlEscape = ->
  s = this
  s = s.replace '&', '&amp;'
  s = s.replace '<', '&lt;'
  s = s.replace '>', '&gt;'
  s


#####################################################################
# Upload form handling
#####################################################################

init_upload_form = (selector, init_date) ->

  init_date_picker = selector ->
    $elem = $ selector
    $elem.datepicker
      showOn:             "both"
      buttonImage:        "/images/caledar_icon.png"
      buttonImageOnly:    true
      firstDay:           1
      selectOtherMonths:  true
      dateFormat:         "yy-mm-dd"

  current_date_string = ->
    $elem = $ selector
    
    date  = new Date()
    year  = date.getUTCFullYear()
    month = date.getUTCMonth() + 1
    day   = date.getUTCDate()

    year + "-" + month + "-" + day

  init_date ?= current_date_string()


