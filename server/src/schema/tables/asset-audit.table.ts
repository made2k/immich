import { PrimaryGeneratedUuidV7Column } from 'src/decorators';
import { Column, CreateDateColumn, Generated, Table, Timestamp } from 'src/sql-tools';

@Table('assets_audit')
export class AssetAuditTable {
  @PrimaryGeneratedUuidV7Column()
  id!: Generated<string>;

  @Column({ type: 'uuid', indexName: 'IDX_assets_audit_asset_id' })
  assetId!: string;

  @Column({ type: 'uuid', indexName: 'IDX_assets_audit_owner_id' })
  ownerId!: string;

  @CreateDateColumn({ default: () => 'clock_timestamp()', indexName: 'IDX_assets_audit_deleted_at' })
  deletedAt!: Generated<Timestamp>;
}
