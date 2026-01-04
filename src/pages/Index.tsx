import { useState } from 'react';
import { LandingPage } from '@/components/LandingPage';
import { BookingForm } from '@/components/BookingForm';
import { Helmet } from 'react-helmet-async';

const Index = () => {
  const [showBooking, setShowBooking] = useState(false);

  return (
    <>
      <Helmet>
        <title>Barbearia Elite - Agendamento Online | Moçambique</title>
        <meta name="description" content="Agende seu corte de cabelo ou barba online na Barbearia Elite. Profissionais experientes, atendimento de qualidade em Moçambique." />
      </Helmet>
      
      {showBooking ? (
        <BookingForm onBack={() => setShowBooking(false)} />
      ) : (
        <LandingPage onBookNow={() => setShowBooking(true)} />
      )}
    </>
  );
};

export default Index;
