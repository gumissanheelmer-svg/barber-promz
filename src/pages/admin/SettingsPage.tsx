import { useState, useEffect } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { supabase } from '@/integrations/supabase/client';
import { Settings as SettingsIcon, Save, MessageCircle } from 'lucide-react';
import { useToast } from '@/hooks/use-toast';

interface SettingsData {
  id: string;
  whatsapp_number: string;
  business_name: string;
  opening_time: string;
  closing_time: string;
}

export default function SettingsPage() {
  const { toast } = useToast();
  const [settings, setSettings] = useState<SettingsData | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [isSaving, setIsSaving] = useState(false);

  useEffect(() => {
    fetchSettings();
  }, []);

  const fetchSettings = async () => {
    setIsLoading(true);
    const { data, error } = await supabase
      .from('settings')
      .select('*')
      .limit(1)
      .maybeSingle();

    if (error) {
      console.error('Error fetching settings:', error);
    } else if (data) {
      setSettings(data);
    }
    setIsLoading(false);
  };

  const handleSave = async () => {
    if (!settings) return;

    setIsSaving(true);
    const { error } = await supabase
      .from('settings')
      .update({
        whatsapp_number: settings.whatsapp_number,
        business_name: settings.business_name,
        opening_time: settings.opening_time,
        closing_time: settings.closing_time,
      })
      .eq('id', settings.id);

    if (error) {
      toast({
        title: 'Erro',
        description: 'Não foi possível salvar as configurações.',
        variant: 'destructive',
      });
    } else {
      toast({
        title: 'Sucesso',
        description: 'Configurações salvas com sucesso.',
      });
    }
    setIsSaving(false);
  };

  if (isLoading) {
    return (
      <div className="space-y-6">
        <h1 className="text-3xl font-display font-bold text-foreground">Configurações</h1>
        <Card className="border-border/50 bg-card/80">
          <CardContent className="p-6">
            <div className="space-y-4">
              {[1, 2, 3, 4].map((i) => (
                <div key={i} className="h-12 bg-muted animate-pulse rounded" />
              ))}
            </div>
          </CardContent>
        </Card>
      </div>
    );
  }

  if (!settings) {
    return (
      <div className="space-y-6">
        <h1 className="text-3xl font-display font-bold text-foreground">Configurações</h1>
        <p className="text-muted-foreground">Configurações não encontradas.</p>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h1 className="text-3xl font-display font-bold text-foreground">Configurações</h1>
        <Button variant="gold" onClick={handleSave} disabled={isSaving}>
          <Save className="w-4 h-4 mr-2" />
          {isSaving ? 'Salvando...' : 'Salvar'}
        </Button>
      </div>

      <div className="grid gap-6">
        {/* Business Info */}
        <Card className="border-border/50 bg-card/80">
          <CardHeader>
            <CardTitle className="font-display flex items-center gap-2">
              <SettingsIcon className="w-5 h-5 text-primary" />
              Informações do Negócio
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="space-y-2">
              <Label htmlFor="business_name">Nome da Barbearia</Label>
              <Input
                id="business_name"
                value={settings.business_name}
                onChange={(e) => setSettings({ ...settings, business_name: e.target.value })}
                className="bg-input border-border"
              />
            </div>
            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label htmlFor="opening_time">Horário de Abertura</Label>
                <Input
                  id="opening_time"
                  type="time"
                  value={settings.opening_time}
                  onChange={(e) => setSettings({ ...settings, opening_time: e.target.value })}
                  className="bg-input border-border"
                />
              </div>
              <div className="space-y-2">
                <Label htmlFor="closing_time">Horário de Fechamento</Label>
                <Input
                  id="closing_time"
                  type="time"
                  value={settings.closing_time}
                  onChange={(e) => setSettings({ ...settings, closing_time: e.target.value })}
                  className="bg-input border-border"
                />
              </div>
            </div>
          </CardContent>
        </Card>

        {/* WhatsApp */}
        <Card className="border-border/50 bg-card/80">
          <CardHeader>
            <CardTitle className="font-display flex items-center gap-2">
              <MessageCircle className="w-5 h-5 text-primary" />
              WhatsApp
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="space-y-2">
              <Label htmlFor="whatsapp">Número do WhatsApp</Label>
              <Input
                id="whatsapp"
                value={settings.whatsapp_number}
                onChange={(e) => setSettings({ ...settings, whatsapp_number: e.target.value })}
                placeholder="+258 84 000 0000"
                className="bg-input border-border"
              />
              <p className="text-sm text-muted-foreground">
                Este número será usado para receber confirmações de agendamento.
              </p>
            </div>
          </CardContent>
        </Card>
      </div>
    </div>
  );
}
