import { useBarbershop } from './useBarbershop';

export type BusinessType = 'barbearia' | 'salao' | 'salao_barbearia';

export function useBusinessType() {
  const { barbershop } = useBarbershop();
  
  const businessType = (barbershop?.business_type || 'barbearia') as BusinessType;
  
  return {
    businessType,
    isBarbershop: businessType === 'barbearia',
    isSalon: businessType === 'salao',
    isHybrid: businessType === 'salao_barbearia',
    
    // Dynamic labels based on business type
    professionalLabel: businessType === 'barbearia' ? 'Barbeiro' : 'Profissional',
    professionalsLabel: businessType === 'barbearia' ? 'Barbeiros' : 'Profissionais',
    businessLabel: businessType === 'barbearia' 
      ? 'Barbearia' 
      : businessType === 'salao' 
        ? 'Salão de Beleza' 
        : 'Salão & Barbearia',
    
    // Status options based on business type
    getStatusOptions: () => {
      if (businessType === 'barbearia') {
        return ['pending', 'confirmed', 'completed', 'cancelled'];
      }
      return ['pending', 'confirmed', 'in_progress', 'completed', 'cancelled'];
    },
    
    // Whether professionals should be filtered by service
    shouldFilterProfessionalsByService: businessType !== 'barbearia',
  };
}
