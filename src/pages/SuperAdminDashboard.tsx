import { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { Helmet } from 'react-helmet-async';
import { useAuth } from '@/hooks/useAuth';
import { supabase } from '@/integrations/supabase/client';
import { Logo } from '@/components/Logo';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { useToast } from '@/hooks/use-toast';
import { 
  Shield, 
  Store, 
  Users, 
  Calendar, 
  Check, 
  X, 
  Ban, 
  Clock,
  LogOut,
  RefreshCw,
  Eye
} from 'lucide-react';
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
} from '@/components/ui/alert-dialog';

interface Barbershop {
  id: string;
  name: string;
  slug: string;
  owner_email: string | null;
  approval_status: string;
  created_at: string;
  active: boolean;
}

interface Stats {
  total: number;
  pending: number;
  approved: number;
  blocked: number;
  rejected: number;
}

type FilterStatus = 'all' | 'pending' | 'approved' | 'blocked' | 'rejected';

export default function SuperAdminDashboard() {
  const navigate = useNavigate();
  const { user, isSuperAdmin, isLoading, signOut } = useAuth();
  const { toast } = useToast();
  
  const [barbershops, setBarbershops] = useState<Barbershop[]>([]);
  const [stats, setStats] = useState<Stats>({ total: 0, pending: 0, approved: 0, blocked: 0, rejected: 0 });
  const [filter, setFilter] = useState<FilterStatus>('all');
  const [isDataLoading, setIsDataLoading] = useState(true);
  const [confirmDialog, setConfirmDialog] = useState<{
    open: boolean;
    action: 'approve' | 'reject' | 'block' | 'unblock';
    barbershop: Barbershop | null;
  }>({ open: false, action: 'approve', barbershop: null });

  useEffect(() => {
    if (!isLoading && (!user || !isSuperAdmin)) {
      navigate('/login');
    }
  }, [user, isSuperAdmin, isLoading, navigate]);

  useEffect(() => {
    if (user && isSuperAdmin) {
      fetchBarbershops();
    }
  }, [user, isSuperAdmin]);

  const fetchBarbershops = async () => {
    setIsDataLoading(true);
    try {
      const { data, error } = await supabase
        .from('barbershops')
        .select('*')
        .order('created_at', { ascending: false });

      if (error) throw error;

      setBarbershops(data || []);
      
      // Calculate stats
      const newStats: Stats = {
        total: data?.length || 0,
        pending: data?.filter(b => b.approval_status === 'pending').length || 0,
        approved: data?.filter(b => b.approval_status === 'approved').length || 0,
        blocked: data?.filter(b => b.approval_status === 'blocked').length || 0,
        rejected: data?.filter(b => b.approval_status === 'rejected').length || 0,
      };
      setStats(newStats);
    } catch (error) {
      console.error('Error fetching barbershops:', error);
      toast({
        title: 'Erro',
        description: 'Não foi possível carregar as barbearias.',
        variant: 'destructive',
      });
    } finally {
      setIsDataLoading(false);
    }
  };

  const handleStatusChange = async (barbershop: Barbershop, newStatus: string) => {
    try {
      const { error } = await supabase
        .from('barbershops')
        .update({ 
          approval_status: newStatus,
          active: newStatus === 'approved'
        })
        .eq('id', barbershop.id);

      if (error) throw error;

      toast({
        title: 'Sucesso',
        description: `Barbearia "${barbershop.name}" foi ${
          newStatus === 'approved' ? 'aprovada' :
          newStatus === 'rejected' ? 'rejeitada' :
          newStatus === 'blocked' ? 'bloqueada' : 'desbloqueada'
        }.`,
      });

      fetchBarbershops();
    } catch (error) {
      console.error('Error updating barbershop:', error);
      toast({
        title: 'Erro',
        description: 'Não foi possível atualizar o status.',
        variant: 'destructive',
      });
    }
  };

  const confirmAction = () => {
    if (!confirmDialog.barbershop) return;
    
    const statusMap = {
      approve: 'approved',
      reject: 'rejected',
      block: 'blocked',
      unblock: 'approved',
    };
    
    handleStatusChange(confirmDialog.barbershop, statusMap[confirmDialog.action]);
    setConfirmDialog({ open: false, action: 'approve', barbershop: null });
  };

  const handleSignOut = async () => {
    await signOut();
    navigate('/');
  };

  const filteredBarbershops = filter === 'all' 
    ? barbershops 
    : barbershops.filter(b => b.approval_status === filter);

  const getStatusBadge = (status: string) => {
    switch (status) {
      case 'pending':
        return <Badge variant="outline" className="bg-yellow-500/10 text-yellow-500 border-yellow-500/30"><Clock className="w-3 h-3 mr-1" /> Pendente</Badge>;
      case 'approved':
        return <Badge variant="outline" className="bg-green-500/10 text-green-500 border-green-500/30"><Check className="w-3 h-3 mr-1" /> Aprovada</Badge>;
      case 'rejected':
        return <Badge variant="outline" className="bg-red-500/10 text-red-500 border-red-500/30"><X className="w-3 h-3 mr-1" /> Rejeitada</Badge>;
      case 'blocked':
        return <Badge variant="outline" className="bg-red-500/10 text-red-500 border-red-500/30"><Ban className="w-3 h-3 mr-1" /> Bloqueada</Badge>;
      default:
        return <Badge variant="outline">{status}</Badge>;
    }
  };

  const getActionText = () => {
    switch (confirmDialog.action) {
      case 'approve': return 'aprovar';
      case 'reject': return 'rejeitar';
      case 'block': return 'bloquear';
      case 'unblock': return 'desbloquear';
    }
  };

  if (isLoading || !isSuperAdmin) {
    return (
      <div className="min-h-screen bg-background flex items-center justify-center">
        <div className="animate-pulse text-center">
          <Logo size="lg" />
          <p className="text-muted-foreground mt-4">Carregando...</p>
        </div>
      </div>
    );
  }

  return (
    <>
      <Helmet>
        <title>Super Admin - Painel de Controle</title>
        <meta name="robots" content="noindex, nofollow" />
      </Helmet>

      <div className="min-h-screen bg-background">
        {/* Header */}
        <header className="border-b border-border bg-card/50 backdrop-blur sticky top-0 z-50">
          <div className="container mx-auto px-4 h-16 flex items-center justify-between">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-full bg-primary/20 flex items-center justify-center">
                <Shield className="w-5 h-5 text-primary" />
              </div>
              <div>
                <h1 className="font-bold text-foreground">Super Admin</h1>
                <p className="text-xs text-muted-foreground">{user?.email}</p>
              </div>
            </div>
            <Button variant="outline" size="sm" onClick={handleSignOut}>
              <LogOut className="w-4 h-4 mr-2" />
              Sair
            </Button>
          </div>
        </header>

        <main className="container mx-auto px-4 py-8">
          {/* Stats Cards */}
          <div className="grid grid-cols-2 md:grid-cols-5 gap-4 mb-8">
            <Card className="bg-card/50 border-border/50">
              <CardContent className="p-4 text-center">
                <Store className="w-8 h-8 mx-auto mb-2 text-primary" />
                <p className="text-2xl font-bold text-foreground">{stats.total}</p>
                <p className="text-xs text-muted-foreground">Total</p>
              </CardContent>
            </Card>
            <Card className="bg-yellow-500/5 border-yellow-500/20">
              <CardContent className="p-4 text-center">
                <Clock className="w-8 h-8 mx-auto mb-2 text-yellow-500" />
                <p className="text-2xl font-bold text-yellow-500">{stats.pending}</p>
                <p className="text-xs text-muted-foreground">Pendentes</p>
              </CardContent>
            </Card>
            <Card className="bg-green-500/5 border-green-500/20">
              <CardContent className="p-4 text-center">
                <Check className="w-8 h-8 mx-auto mb-2 text-green-500" />
                <p className="text-2xl font-bold text-green-500">{stats.approved}</p>
                <p className="text-xs text-muted-foreground">Aprovadas</p>
              </CardContent>
            </Card>
            <Card className="bg-red-500/5 border-red-500/20">
              <CardContent className="p-4 text-center">
                <Ban className="w-8 h-8 mx-auto mb-2 text-red-500" />
                <p className="text-2xl font-bold text-red-500">{stats.blocked}</p>
                <p className="text-xs text-muted-foreground">Bloqueadas</p>
              </CardContent>
            </Card>
            <Card className="bg-red-500/5 border-red-500/20">
              <CardContent className="p-4 text-center">
                <X className="w-8 h-8 mx-auto mb-2 text-red-400" />
                <p className="text-2xl font-bold text-red-400">{stats.rejected}</p>
                <p className="text-xs text-muted-foreground">Rejeitadas</p>
              </CardContent>
            </Card>
          </div>

          {/* Filters */}
          <div className="flex flex-wrap gap-2 mb-6">
            <Button
              variant={filter === 'all' ? 'default' : 'outline'}
              size="sm"
              onClick={() => setFilter('all')}
            >
              Todas ({stats.total})
            </Button>
            <Button
              variant={filter === 'pending' ? 'default' : 'outline'}
              size="sm"
              onClick={() => setFilter('pending')}
              className={filter === 'pending' ? '' : 'border-yellow-500/30 text-yellow-500 hover:bg-yellow-500/10'}
            >
              Pendentes ({stats.pending})
            </Button>
            <Button
              variant={filter === 'approved' ? 'default' : 'outline'}
              size="sm"
              onClick={() => setFilter('approved')}
              className={filter === 'approved' ? '' : 'border-green-500/30 text-green-500 hover:bg-green-500/10'}
            >
              Aprovadas ({stats.approved})
            </Button>
            <Button
              variant={filter === 'blocked' ? 'default' : 'outline'}
              size="sm"
              onClick={() => setFilter('blocked')}
              className={filter === 'blocked' ? '' : 'border-red-500/30 text-red-500 hover:bg-red-500/10'}
            >
              Bloqueadas ({stats.blocked})
            </Button>
            <Button
              variant="ghost"
              size="sm"
              onClick={fetchBarbershops}
              disabled={isDataLoading}
            >
              <RefreshCw className={`w-4 h-4 mr-2 ${isDataLoading ? 'animate-spin' : ''}`} />
              Atualizar
            </Button>
          </div>

          {/* Barbershops List */}
          <div className="space-y-4">
            {isDataLoading ? (
              <div className="text-center py-12">
                <RefreshCw className="w-8 h-8 animate-spin mx-auto text-primary mb-4" />
                <p className="text-muted-foreground">Carregando barbearias...</p>
              </div>
            ) : filteredBarbershops.length === 0 ? (
              <Card className="bg-card/50">
                <CardContent className="py-12 text-center">
                  <Store className="w-12 h-12 mx-auto mb-4 text-muted-foreground/50" />
                  <p className="text-muted-foreground">Nenhuma barbearia encontrada.</p>
                </CardContent>
              </Card>
            ) : (
              filteredBarbershops.map((barbershop) => (
                <Card key={barbershop.id} className="bg-card/50 border-border/50 hover:border-primary/30 transition-colors">
                  <CardContent className="p-4">
                    <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
                      <div className="flex-1">
                        <div className="flex items-center gap-3 mb-2">
                          <h3 className="font-bold text-lg text-foreground">{barbershop.name}</h3>
                          {getStatusBadge(barbershop.approval_status)}
                        </div>
                        <div className="text-sm text-muted-foreground space-y-1">
                          <p><strong>Slug:</strong> /b/{barbershop.slug}</p>
                          <p><strong>Email:</strong> {barbershop.owner_email || 'Não informado'}</p>
                          <p><strong>Data:</strong> {new Date(barbershop.created_at).toLocaleDateString('pt-BR')}</p>
                        </div>
                      </div>
                      <div className="flex flex-wrap gap-2">
                        <Button
                          variant="outline"
                          size="sm"
                          onClick={() => window.open(`/b/${barbershop.slug}`, '_blank')}
                        >
                          <Eye className="w-4 h-4 mr-1" />
                          Ver
                        </Button>
                        
                        {barbershop.approval_status === 'pending' && (
                          <>
                            <Button
                              variant="outline"
                              size="sm"
                              className="border-green-500/30 text-green-500 hover:bg-green-500/10"
                              onClick={() => setConfirmDialog({ open: true, action: 'approve', barbershop })}
                            >
                              <Check className="w-4 h-4 mr-1" />
                              Aprovar
                            </Button>
                            <Button
                              variant="outline"
                              size="sm"
                              className="border-red-500/30 text-red-500 hover:bg-red-500/10"
                              onClick={() => setConfirmDialog({ open: true, action: 'reject', barbershop })}
                            >
                              <X className="w-4 h-4 mr-1" />
                              Rejeitar
                            </Button>
                          </>
                        )}
                        
                        {barbershop.approval_status === 'approved' && (
                          <Button
                            variant="outline"
                            size="sm"
                            className="border-red-500/30 text-red-500 hover:bg-red-500/10"
                            onClick={() => setConfirmDialog({ open: true, action: 'block', barbershop })}
                          >
                            <Ban className="w-4 h-4 mr-1" />
                            Bloquear
                          </Button>
                        )}
                        
                        {(barbershop.approval_status === 'blocked' || barbershop.approval_status === 'rejected') && (
                          <Button
                            variant="outline"
                            size="sm"
                            className="border-green-500/30 text-green-500 hover:bg-green-500/10"
                            onClick={() => setConfirmDialog({ open: true, action: 'unblock', barbershop })}
                          >
                            <Check className="w-4 h-4 mr-1" />
                            Aprovar
                          </Button>
                        )}
                      </div>
                    </div>
                  </CardContent>
                </Card>
              ))
            )}
          </div>
        </main>
      </div>

      {/* Confirmation Dialog */}
      <AlertDialog open={confirmDialog.open} onOpenChange={(open) => setConfirmDialog(prev => ({ ...prev, open }))}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>Confirmar Ação</AlertDialogTitle>
            <AlertDialogDescription>
              Tem certeza que deseja {getActionText()} a barbearia "{confirmDialog.barbershop?.name}"?
              {confirmDialog.action === 'block' && (
                <span className="block mt-2 text-red-500">
                  A barbearia perderá acesso ao sistema até ser desbloqueada.
                </span>
              )}
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel>Cancelar</AlertDialogCancel>
            <AlertDialogAction onClick={confirmAction}>
              Confirmar
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </>
  );
}
