export interface Service {
  id: string;
  name: string;
  price: number;
  duration: number;
  active: boolean;
  created_at: string;
  updated_at: string;
}

export interface Barber {
  id: string;
  name: string;
  phone: string | null;
  active: boolean;
  working_hours: WorkingHours;
  created_at: string;
  updated_at: string;
}

export interface WorkingHours {
  monday: DayHours | null;
  tuesday: DayHours | null;
  wednesday: DayHours | null;
  thursday: DayHours | null;
  friday: DayHours | null;
  saturday: DayHours | null;
  sunday: DayHours | null;
}

export interface DayHours {
  start: string;
  end: string;
}

export interface BarberService {
  id: string;
  barber_id: string;
  service_id: string;
}

export interface Appointment {
  id: string;
  client_name: string;
  client_phone: string;
  barber_id: string;
  service_id: string;
  appointment_date: string;
  appointment_time: string;
  status: 'pending' | 'confirmed' | 'cancelled' | 'completed';
  notes: string | null;
  created_at: string;
  updated_at: string;
  barber?: Barber;
  service?: Service;
}

export interface Settings {
  id: string;
  whatsapp_number: string;
  business_name: string;
  opening_time: string;
  closing_time: string;
  created_at: string;
  updated_at: string;
}

export interface BookingFormData {
  clientName: string;
  clientPhone: string;
  barberId: string;
  serviceId: string;
  appointmentDate: Date;
  appointmentTime: string;
}
