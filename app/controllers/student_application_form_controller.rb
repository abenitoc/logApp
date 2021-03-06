require "prawn"

class StudentApplicationFormController < ApplicationController
	before_action :authenticate_user!
	before_action :validate_admin?, only: [:review_step]

	include PdfHelper
	def sap_page
		@sap = current_user.student_application_form
		render "student_application_form/student_application_form"
	end

	def personal_data
		@user = current_user
		render "student_application_form/personal_data_step"
	end

	def review_step
		user = User.find(params[:user])
		if user.role == "admin"
			redirect_back fallback_location: root_path
		else
			render "student_application_form/review_student_application_form"
		end
	end

	def review_personal_data_step
		user = User.find(params[:user])
		if user.role == "admin"
			redirect_back fallback_location: root_path
		else
			render "student_application_form/review_personal_data_step"
		end
	end

	def change_step
		if !params[:step].blank?
			@sap = current_user.student_application_form
			@sap.step = params[:step].to_i
			@sap.save!
		end
		render "student_application_form/student_application_form"
	end

	def save
		@sap = current_user.student_application_form
		from_ball = params[:from_ball] == "true"
		unless params[:step] == "personal_data"
			step = params[:step].to_i
			step = nil if (step.to_s != params[:step])
		else
			step = 1
		end
		if !params[:student_application_form][:purpose_of_stay].blank?
			@sap.purpose_of_stay = params[:student_application_form][:purpose_of_stay]
			if params[:student_application_form][:purpose_of_stay].include?("other")
				@sap.other_purpose = params[:student_application_form][:other_purpose]
			else
				@sap.other_purpose = nil
			end
		elsif	params[:student_application_form][:other_purpose]
			 @sap.other_purpose = nil
			 @sap.purpose_of_stay = nil
		end
		if !params[:student_application_form][:other_languages].blank?
			@sap.languages.destroy_all
			if !params[:student_application_form][:languages].blank?
				languages = params[:student_application_form][:languages]
				languages.each do |language|
					lan = Language.new
					lan.name = language[:name]
					lan.currently_studying = language[:currently_studying].to_s == 'on' ? true : false 
					lan.able_follow_lectures = language[:able_follow_lectures].to_s == 'on' ? true : false 
					lan.able_follow_lectures_extra_preparation = language[:able_follow_lectures_extra_preparation].to_s == 'on' ? true : false 
					@sap.languages << lan
					lan.save!
				end
			end
		end
		if params[:student_application_form][:no_work_experience] == "0"
			
			@sap.work_experiences.destroy_all
			if !params[:student_application_form][:work_experiences].blank? 
				wexes = params[:student_application_form][:work_experiences]
				wexes.each do |wex|
					we = WorkExperience.new
					we.work_kind = wex[:work_kind]
					we.country = wex[:country]
					we.firm_organisation = wex[:firm_organisation]
					we.from = wex[:from]
					we.to = wex[:to]
					@sap.work_experiences << we
					we.save!
				end
			end
		elsif params[:student_application_form][:no_work_experience] == "1" 
			@sap.work_experiences.destroy_all
		end
		
	
	    #//:seeking_degree
		if params[:student_application_form][:seeking_degree]
	    	user = @sap.user
	    	user.seeking_degree = params[:student_application_form][:seeking_degree] == "1"
	    	user.save!
	    	params[:student_application_form].delete :seeking_degree
		end
		if params[:student_application_form]
			@sap.assign_attributes(params.require(:student_application_form).permit(
					:inst_sending_name,
					:inst_adress,
					:school_family_dpt,
					:erasmus_code,
					:dept_coordinator,
					:contact_person,
					:inst_telephone,
					:inst_email,
					:academic_year,
					:programme,
					:field_of_study,
					:reasons_abroad,
					:mother_tongue,
					:language_instruction,
					:current_diploma_degree,
					:year_attended,
					:specialization_area,
					:already_study_abroad,
					:where_study_abroad,
					:where_institution_abroad,
					:no_work_experience
				))

			@sap.save!
		end
		# render "student_application_form/student_application_form"
		if params[:step] == "personal_data"
			if !from_ball
				redirect_to student_application_form_personal_data_step_path
			else
				redirect_to student_application_form_personal_data_step_path(:from_ball => from_ball)
			end
		elsif !step.blank? and step.between?(1,6)
			if !from_ball
				redirect_to "#{student_application_form_path}/#{step}"
			else 
				redirect_to "#{student_application_form_path}/#{step}?from_ball=#{from_ball}"
			end
		else
			redirect_to user_dashboard_path
		end
	end


	def generate_pdf
		unless current_user.role === 'admin' 
			send_data create_pdf(current_user), :filename => "application_form.pdf", :type => "application/pdf"
		else
			if User.exists?(params[:user])
				user = User.find(params[:user])
				send_data create_pdf(user), :filename => "application_form.pdf", :type => "application/pdf"
			else
				redirect_to admin_dashboard_path
			end
		end
	end


	private

	def languages_params
		params.require(:languages).permit(
					:languages,
					:name,
					:currently_studying,
					:able_follow_lectures,
					:able_follow_lectures_extra_preparation
		)
	end

	def toNumeral(number)
		numeralhash = {1=>"first", 2=>"second", 3=>"third", 4=>"fourth",5=>"fifth",6=>"sixth",7=>"seventh"}
		if numeralhash.has_key?number
			numeralhash[number]
		else
			"first"
		end
	end



end
